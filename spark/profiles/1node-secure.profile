{
  "os": "centos7",
  "hdp_short_version": "2.3.4",
  "vm_mem": 6144,
  "vm_cpus": 4,

  "am_mem": 512,
  "server_mem": 768,
  "client_mem": 1024,

  "security": true,
  "domain": "example.com",
  "realm": "EXAMPLE.COM",

  "clients" : [ "hdfs", "hive", "tez", "yarn" ],
  "nodes": [
    {"hostname": "hdp-secure", "ip": "192.168.59.12",
     "roles": ["client", "hive-db", "hive-meta", "hive-server2", "kdc", "nn", "slave", "yarn", "yarn-timelineserver"]}
  ],

  "hive_options" : "interactive",

  "extras": [ "sample-hive-data" ]
}
