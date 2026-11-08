variable "prefix" {
  description = "Префикс имён ресурсов среды"
  type        = string
}

variable "zone" {
  description = "Зона доступности публичной подсети и bastion"
  type        = string
}

variable "app_zone" {
  description = "Зона доступности приватной подсети, приложения и диска данных"
  type        = string
}

variable "public_cidr" {
  description = "CIDR публичной подсети (bastion)"
  type        = string
}

variable "private_cidr" {
  description = "CIDR приватной подсети (приложения и данные)"
  type        = string
}

variable "admin_cidrs" {
  description = "Сети, из которых разрешён SSH на bastion"
  type        = list(string)
}

variable "image_family" {
  description = "Семейство образа ОС"
  type        = string
}

variable "platform_id" {
  description = "Платформа виртуальных машин"
  type        = string
}

variable "preemptible" {
  description = "Прерываемые ВМ (дешевле, для тестовых сред)"
  type        = bool
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
}

variable "data_disk" {
  description = "Диск данных приложения"
  type = object({
    type = string
    size = number
  })
}

variable "ssh_user" {
  description = "Пользователь для SSH-доступа"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Путь к публичному SSH-ключу"
  type        = string
}
