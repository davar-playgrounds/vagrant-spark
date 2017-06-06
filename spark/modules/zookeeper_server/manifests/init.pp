#  Licensed to the Apache Software Foundation (ASF) under one or more
#   contributor license agreements.  See the NOTICE file distributed with
#   this work for additional information regarding copyright ownership.
#   The ASF licenses this file to You under the Apache License, Version 2.0
#   (the "License"); you may not use this file except in compliance with
#   the License.  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

class zookeeper_server {
  require zookeeper_client

  $path="/bin:/sbin:/usr/bin:/usr/sbin"
  $component = "zookeeper-server"
  if ($hdp_version_major+0 <= 2 and $hdp_version_minor+0 <= 2) {
    $start_script="/usr/hdp/$hdp_version/etc/$platform_start_script_path/$component"
  }
  else {
    $start_script="/usr/hdp/$hdp_version/zookeeper/etc/$platform_start_script_path/$component"
  }

  if $security == "true" {
    file { "${zookeeper_client::conf_dir}/zookeeper-server.jaas":
      ensure => file,
      content => template('zookeeper_server/zookeeper-server.erb'),
    }
    -> Service["zookeeper-server"]

    file { "${hdfs_client::keytab_dir}/zookeeper.keytab":
      ensure => file,
      source => "/vagrant/generated/keytabs/${hostname}/zookeeper.keytab",
      owner => zookeeper,
      group => hadoop,
      mode => '400',
    }
    -> Service["zookeeper-server"]
  }

  case $operatingsystem {
    'centos': {
      package { "zookeeper${package_version}-server":
        ensure => installed,
        before => Exec["hdp-select set zookeeper-server ${hdp_version}"],
      }
      if ($hdp_version_major+0 == 2 and $hdp_version_minor+0 == 3 and $hdp_version_patch+0 == 2) {
        file { "$start_script":
          ensure => 'file',
          source => 'puppet:///modules/zookeeper_server/zookeeper-server',
          replace => true,
          require => Package["zookeeper${package_version}-server"],
          before => Service["zookeeper-server"],
        }
      }
    }
    'ubuntu': {
      if ($hdp_version_major+0 <= 2 and $hdp_version_minor+0 < 3) {
        # XXX: Work around BUG-39010.
        exec { "apt-get download zookeeper${package_version}-server":
          cwd => "/tmp",
          path => "$path",
        }
        ->
        exec { "dpkg -i --force-overwrite zookeeper${package_version}*.deb":
          cwd => "/tmp",
          path => "$path",
          user => "root",
        }
        # Fix incorrect startup script permissions.
        ->
        file { "/usr/hdp/${hdp_version}/etc/init.d/zookeeper-server":
          ensure => file,
          mode => '755',
          before => Exec["hdp-select set zookeeper-server ${hdp_version}"],
        }
      }
      else {
        package { "zookeeper${package_version}-server":
          ensure => installed,
          before => Exec["hdp-select set zookeeper-server ${hdp_version}"],
        }
      }
    }
  }

  exec { "hdp-select set zookeeper-server ${hdp_version}":
    cwd => "/",
    path => "$path",
  }
  ->
  file { "${zookeeper_client::conf_dir}/configuration.xsl":
    ensure => file,
    content => template('zookeeper_server/configuration.erb'),
  }
  ->
  file { "${zookeeper_client::data_dir}":
    ensure => directory,
    owner => zookeeper,
    group => hadoop,
    mode => '700',
  }
  ->
  file { "${zookeeper_client::data_dir}/myid":
    ensure => file,
    content => template('zookeeper_server/myid.erb'),
  }
  ->
  file { "${zookeeper_client::log_dir}":
    ensure => directory,
    owner => zookeeper,
    group => hadoop,
    mode => '700',
  }
  ->
  file { "${zookeeper_client::pid_dir}":
    ensure => directory,
    owner => zookeeper,
    group => hadoop,
    mode => '755',
  }
  ->
  exec { "usermod -a -G hadoop zookeeper":
    # This hack allows zookeeper to read its keytab in secure. Need to move to per-directory.
    path => "$path",
  }
  ->
  service { "zookeeper-server":
    ensure => running,
    enable => true,
  }

  # Startup.
  if ($operatingsystem == "centos" and $operatingsystemmajrelease == "7") {
    file { "/etc/systemd/system/zookeeper-server.service":
      ensure => 'file',
      source => "/vagrant/files/systemd/zookeeper-server.service",
      before => Service["zookeeper-server"],
    }
    file { "/etc/systemd/system/zookeeper-server.service.d":
      ensure => 'directory',
    } ->
    file { "/etc/systemd/system/zookeeper-server.service.d/default.conf":
      ensure => 'file',
      source => "/vagrant/files/systemd/zookeeper-server.service.d/default.conf",
      before => Service["zookeeper-server"],
    }
  } else {
    file { "/etc/init.d/zookeeper-server":
      ensure => 'link',
      target => "$start_script",
      before => Service["zookeeper-server"],
    }
  }
}
