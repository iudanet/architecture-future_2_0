terraform {
  required_version = ">= 1.5"
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.140"
    }
  }

  # В проде state хранится в Object Storage (бакет создаётся вручную):
  # backend "s3" {
  #   endpoints = { s3 = "https://storage.yandexcloud.net" }
  #   bucket    = "future20-tfstate"
  #   key       = "domain-env/terraform.tfstate"
  #   region    = "ru-central1"
  #   skip_region_validation      = true
  #   skip_credentials_validation = true
  #   skip_requesting_account_id  = true
  #   skip_s3_checksum            = true
  # }
}

# Токен, облако и каталог берутся из окружения: YC_TOKEN, YC_CLOUD_ID, YC_FOLDER_ID.
provider "yandex" {
  zone = var.zone
}

data "yandex_compute_image" "ubuntu" {
  family = var.image_family
}

locals {
  ssh_metadata = "${var.ssh_user}:${file(pathexpand(var.ssh_public_key_path))}"
  labels       = { project = var.prefix, managed-by = "terraform" }
}

# ---------- Сеть ----------
resource "yandex_vpc_network" "main" {
  name   = "${var.prefix}-net"
  labels = local.labels
}

resource "yandex_vpc_gateway" "nat" {
  name   = "${var.prefix}-nat"
  labels = local.labels
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "private" {
  name       = "${var.prefix}-private-rt"
  network_id = yandex_vpc_network.main.id
  labels     = local.labels

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat.id
  }
}

resource "yandex_vpc_subnet" "public" {
  name           = "${var.prefix}-public"
  zone           = var.zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.public_cidr]
  labels         = local.labels
}

resource "yandex_vpc_subnet" "private" {
  name           = "${var.prefix}-private"
  zone           = var.app_zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.private_cidr]
  route_table_id = yandex_vpc_route_table.private.id
  labels         = local.labels
}

# ---------- Группы безопасности ----------
resource "yandex_vpc_security_group" "bastion" {
  name       = "${var.prefix}-bastion-sg"
  network_id = yandex_vpc_network.main.id
  labels     = local.labels

  ingress {
    description    = "SSH from admin networks"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = var.admin_cidrs
  }

  egress {
    description    = "Any outbound"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "app" {
  name       = "${var.prefix}-app-sg"
  network_id = yandex_vpc_network.main.id
  labels     = local.labels

  ingress {
    description       = "SSH only from bastion"
    protocol          = "TCP"
    port              = 22
    security_group_id = yandex_vpc_security_group.bastion.id
  }

  ingress {
    description    = "HTTPS inside VPC"
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = [var.private_cidr]
  }

  egress {
    description    = "Outbound via NAT"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------- Виртуальные машины и диски ----------
resource "yandex_compute_instance" "bastion" {
  name                      = "${var.prefix}-bastion"
  hostname                  = "${var.prefix}-bastion"
  platform_id               = var.platform_id
  zone                      = var.zone
  labels                    = local.labels
  allow_stopping_for_update = true

  resources {
    cores         = var.bastion.cores
    memory        = var.bastion.memory
    core_fraction = var.bastion.core_fraction
  }

  scheduling_policy {
    preemptible = var.preemptible
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      type     = var.bastion.disk_type
      size     = var.bastion.disk_size
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.bastion.id]
  }

  # Новый образ семейства не должен пересоздавать работающие ВМ.
  lifecycle {
    ignore_changes = [boot_disk[0].initialize_params[0].image_id]
  }

  metadata = {
    ssh-keys = local.ssh_metadata
  }
}

resource "yandex_compute_disk" "data" {
  name   = "${var.prefix}-data"
  zone   = var.app_zone
  type   = var.data_disk.type
  size   = var.data_disk.size
  labels = local.labels
}

resource "yandex_compute_instance" "app" {
  name                      = "${var.prefix}-app"
  hostname                  = "${var.prefix}-app"
  platform_id               = var.platform_id
  zone                      = var.app_zone
  labels                    = local.labels
  allow_stopping_for_update = true

  resources {
    cores         = var.app.cores
    memory        = var.app.memory
    core_fraction = var.app.core_fraction
  }

  scheduling_policy {
    preemptible = var.preemptible
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      type     = var.app.disk_type
      size     = var.app.disk_size
    }
  }

  secondary_disk {
    disk_id     = yandex_compute_disk.data.id
    device_name = "data"
  }

  # Без публичного IP: исходящий трафик через NAT-шлюз, вход — только с bastion.
  network_interface {
    subnet_id          = yandex_vpc_subnet.private.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.app.id]
  }

  # Новый образ семейства не должен пересоздавать работающие ВМ.
  lifecycle {
    ignore_changes = [boot_disk[0].initialize_params[0].image_id]
  }

  metadata = {
    ssh-keys = local.ssh_metadata
  }
}
