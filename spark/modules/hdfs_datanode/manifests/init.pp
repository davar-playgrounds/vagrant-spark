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

class hdfs_datanode {
  require hdfs_client
  require hadoop_server

  $path="/usr/bin"

  $component = "hadoop-hdfs-datanode"
  if ($hdp_version_major+0 <= 2 and $hdp_version_minor+0 <= 2) {
    $start_script="/usr/hdp/$hdp_version/etc/$platform_start_script_path/$component"
  }
  else {
    $start_script="/usr/hdp/$hdp_version/hadoop-hdfs/etc/$platform_start_script_path/$component"
  }

  if $security == "true" {
    require kerberos_http

    file { "${hdfs_client::keytab_dir}/dn.keytab":
      ensure => file,
      source => "/vagrant/generated/keytabs/${hostname}/dn.keytab",
      owner => hdfs,
      group => hadoop,
      mode => '400',
    }
    ->
    Package["hadoop${package_version}-hdfs-datanode"]
  }

  package { "hadoop${package_version}-hdfs-datanode" :
    ensure => installed,
  }
  ->
  exec { "hdp-select set hadoop-hdfs-datanode ${hdp_version}":
    cwd => "/",
    path => "$path",
  }
  ->
  service {"hadoop-hdfs-datanode":
    ensure => running,
    enable => true,
  }

  # Startup.
  if ($operatingsystem == "centos" and $operatingsystemmajrelease == "7") {
    file { "/etc/systemd/system/hadoop-hdfs-datanode.service":
      ensure => 'file',
      source => "/vagrant/files/systemd/hadoop-hdfs-datanode.service",
      before => Service["hadoop-hdfs-datanode"],
    }
    file { "/etc/systemd/system/hadoop-hdfs-datanode.service.d":
      ensure => 'directory',
    } ->
    file { "/etc/systemd/system/hadoop-hdfs-datanode.service.d/default.conf":
      ensure => 'file',
      source => "/vagrant/files/systemd/hadoop-hdfs-datanode.service.d/default.conf",
      before => Service["hadoop-hdfs-datanode"],
    }
  } else {
    file { "/etc/init.d/hadoop-hdfs-datanode":
      ensure => 'link',
      target => "$start_script",
      before => Service["hadoop-hdfs-datanode"],
    }
  }
}
