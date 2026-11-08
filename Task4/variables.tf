variable "prefix" {
  description = "Префикс имён ресурсов среды"
  type        = string
}

variable "zone" {
  description = "Зона доступности публичной подсети и bastion"
  type        = string
  default     = "ru-central1-a"
}

variable "app_zone" {
  description = "Зона доступности приватной подсети, приложения и диска данных"
  type        = string
  default     = "ru-central1-a"
}

variable "public_cidr" {
  description = "CIDR публичной подсети (bastion)"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.public_cidr))
    error_message = "public_cidr должен быть корректным IPv4 CIDR."
  }
}

variable "private_cidr" {
  description = "CIDR приватной подсети (приложения и данные)"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.private_cidr))
    error_message = "private_cidr должен быть корректным IPv4 CIDR."
  }
}

variable "admin_cidrs" {
  description = "Сети, из которых разрешён SSH на bastion"
  type        = list(string)

  validation {
    condition     = length(var.admin_cidrs) > 0 && !contains(var.admin_cidrs, "0.0.0.0/0")
    error_message = "Укажите конкретные адреса администраторов; 0.0.0.0/0 запрещён."
  }
}

variable "image_family" {
  description = "Семейство образа ОС"
  type        = string
  default     = "ubuntu-2204-lts"
}

variable "platform_id" {
  description = "Платформа виртуальных машин"
  type        = string
  default     = "standard-v3"
}

variable "preemptible" {
  description = "Прерываемые ВМ (дешевле, для тестовых сред)"
  type        = bool
  default     = false
}

variable "bastion" {
  description = "Параметры ВМ bastion"
  type = object({
    cores         = number
    memory        = number
    core_fraction = number
    disk_type     = string
    disk_size     = number
  })

  validation {
    condition     = contains([20, 50, 100], var.bastion.core_fraction) && contains(["network-hdd", "network-ssd"], var.bastion.disk_type)
    error_message = "core_fraction: 20, 50 или 100; disk_type: network-hdd или network-ssd."
  }
}

variable "app" {
  description = "Параметры ВМ приложения"
  type = object({
    cores         = number
    memory        = number
    core_fraction = number
    disk_type     = string
    disk_size     = number
  })

  validation {
    condition     = contains([20, 50, 100], var.app.core_fraction) && contains(["network-hdd", "network-ssd"], var.app.disk_type)
    error_message = "core_fraction: 20, 50 или 100; disk_type: network-hdd или network-ssd."
  }
}

variable "data_disk" {
  description = "Диск данных приложения"
  type = object({
    type = string
    size = number
  })

  validation {
    condition     = contains(["network-hdd", "network-ssd"], var.data_disk.type)
    error_message = "type: network-hdd или network-ssd."
  }
}

variable "ssh_user" {
  description = "Пользователь для SSH-доступа"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key_path" {
  description = "Путь к публичному SSH-ключу"
  type        = string
}
