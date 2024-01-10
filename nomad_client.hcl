client {
  enabled = true
  servers = ["${NOMAD_SERVER}:4647"]
}

plugin "raw_exec" {
  config {
    enabled = true
  }
}

data_dir = "/home/ubuntu/nomad_tmp"