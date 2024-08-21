server {
  enabled          = true
  bootstrap_expect = "${expect}"
  server_join {
    retry_join     = ["provider=aws tag_key=Nomad_role tag_value=${role}"]
    retry_max      = 5
    retry_interval = "15s"
  }
}

data_dir  = "/home/ubuntu/nomad_tmp"
log_level = "debug"
