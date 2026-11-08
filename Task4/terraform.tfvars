prefix       = "future20"
zone         = "ru-central1-a"
app_zone     = "ru-central1-d"
public_cidr  = "10.20.1.0/24"
private_cidr = "10.20.2.0/24"
admin_cidrs  = ["203.0.113.10/32"] # адрес рабочего места администратора / VPN

image_family = "ubuntu-2204-lts"
platform_id  = "standard-v3"
preemptible  = true

bastion = {
  cores         = 2
  memory        = 2
  core_fraction = 20
  disk_type     = "network-hdd"
  disk_size     = 15
}

app = {
  cores         = 2
  memory        = 4
  core_fraction = 50
  disk_type     = "network-hdd" # в проде — network-ssd
  disk_size     = 15
}

data_disk = {
  type = "network-ssd"
  size = 10
}

ssh_user            = "ubuntu"
ssh_public_key_path = "~/.ssh/id_ed25519.pub"
