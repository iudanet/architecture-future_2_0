output "network_id" {
  description = "ID сети VPC"
  value       = yandex_vpc_network.main.id
}

output "subnets" {
  description = "Подсети"
  value = {
    public  = { id = yandex_vpc_subnet.public.id, cidr = var.public_cidr }
    private = { id = yandex_vpc_subnet.private.id, cidr = var.private_cidr }
  }
}

output "nat_gateway_id" {
  description = "ID NAT-шлюза приватной подсети"
  value       = yandex_vpc_gateway.nat.id
}

output "bastion_public_ip" {
  description = "Публичный IP bastion"
  value       = yandex_compute_instance.bastion.network_interface[0].nat_ip_address
}

output "app_private_ip" {
  description = "Внутренний IP ВМ приложения"
  value       = yandex_compute_instance.app.network_interface[0].ip_address
}

output "ssh_to_app" {
  description = "Подключение к приложению через bastion"
  value       = "ssh -J ${var.ssh_user}@${yandex_compute_instance.bastion.network_interface[0].nat_ip_address} ${var.ssh_user}@${yandex_compute_instance.app.network_interface[0].ip_address}"
}
