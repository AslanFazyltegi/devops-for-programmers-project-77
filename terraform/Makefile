# Terraform команды для создания ресурсов ВМ
tf-create-cloud-structure:
	terraform apply -target=yandex_vpc_network.net \
     -target=yandex_vpc_subnet.subnet \
     -target=yandex_vpc_address.vhosting-ext-ip \
     -target=yandex_vpc_security_group.sg-balancer \
     -target=yandex_vpc_security_group.sg-vms \
     -target=yandex_compute_instance_group.ig-a

# Получение IP-адресов и создание инвентаря Ansible
tf-get-vm-ips:
	terraform output instance_ips
	terraform apply -target=local_file.inventory

# Получение IP-адресов для целевых групп
tf-get-tg-ips:
	terraform output vhosting-ext-ip 

# Terraform команды для создания ALB
tf-create-cloud-alb:
	terraform apply -target=yandex_alb_target_group.vhosting-tg-a \
    -target=yandex_alb_http_router.vhosting-router-a \
    -target=yandex_alb_backend_group.vhosting-bg-a \
    -target=yandex_alb_virtual_host.vhosting-host-a \
    -target=yandex_alb_load_balancer.vhosting-alb

tf-destroy:
	terraform destroy
