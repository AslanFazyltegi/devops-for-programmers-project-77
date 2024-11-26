resource "yandex_vpc_network" "net" {
  name        = "vhosting-network"
  description = "vhosting-network"
}

resource "yandex_vpc_subnet" "subnet" {
depends_on = [yandex_vpc_network.net]
  name           = "vhosting-subnet"
  zone           = var.zone_id
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = ["192.168.192.0/24"]
}

resource "yandex_vpc_address" "vhosting-ext-ip" {
  name = "vhosting-ext-ip"
  external_ipv4_address {
    zone_id = var.zone_id
  }
}

resource "yandex_vpc_security_group" "sg-balancer" {
  name        = "vhosting-sg-balancer"
  description = "vhosting-sg-balancer"
  network_id  = yandex_vpc_network.net.id

  ingress {
    protocol       = "ICMP"
    description    = "Ping rule"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535    
  }
  ingress {
    description = "Allow HTTP traffic"
    protocol    = "TCP"
    port        = "80"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow HTTPS traffic"
    protocol    = "TCP"
    port        = "443"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow healthchecks"
    protocol    = "TCP"
    port        = "30080"
    predefined_target = "loadbalancer_healthchecks"
  }
  
  egress {
    description = "Allow all outgoing traffic"
    protocol    = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }  
}


resource "yandex_vpc_security_group" "sg-vms" {
depends_on = [yandex_vpc_security_group.sg-balancer]
  name        = "vhosting-sg-vms"
  description = "vhosting-sg-vms"
  network_id  = yandex_vpc_network.net.id
  
  ingress {
    protocol       = "ICMP"
    description    = "Ping rule"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }

  ingress {
    description = "SSH"
    protocol    = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = "22"
  }
  ingress {
    description = "APP"
    protocol    = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = "3000"
  }
  ingress {
    protocol = "TCP"
    description = "Allow All from Balancer"
    security_group_id = yandex_vpc_security_group.sg-balancer.id
    from_port      = 0
    to_port        = 65535
  }
  egress {
    description = "Allow all outgoing traffic"
    protocol    = "Any"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

resource "yandex_compute_instance_group" "ig-a" {
depends_on = [yandex_vpc_subnet.subnet,yandex_vpc_security_group.sg-vms]

  name                = "vhosting-ig-a"
  folder_id           = var.yc_folder_id
  service_account_id  = var.service_account_id
  description = "Instance group for vhosting with Ubuntu20 stack"

  instance_template {
    platform_id  = "standard-v2" # Intel Ice Lake
    resources {
      cores         = 2
      memory        = 4
      core_fraction = 100 
    }
        boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        image_id = "fd81id4ciatai2csff2u"
        size     = 20
      }
    }
    network_interface {
      network_id         = yandex_vpc_network.net.id
      subnet_ids          = [yandex_vpc_subnet.subnet.id]
          security_group_ids = [yandex_vpc_security_group.sg-vms.id]
          nat                = true
    }
    metadata = {
      ssh-keys = "admin:${file("/root/hexlet/hexletyandexubuntu1sshrsa.pub")}"
user-data = <<-EOF
  #cloud-config
  datasource:
    Ec2:
    strict_id: false
  ssh_pwauth: yes
  users:
    - name: admin
      sudo: ALL=(ALL) NOPASSWD:ALL
      shell: /bin/bash
      ssh_authorized_keys:
        - ${file("/root/hexlet/hexletyandexubuntu1sshrsa.pub")}
  packages:
    - openssh-server
  runcmd:
    - apt update && apt upgrade -y && apt install -y openssh-server openssh-client
    - systemctl enable ssh
    - systemctl start ssh
EOF
    }
  }

  scale_policy {
    fixed_scale {
      size = 2
    }
  }

  allocation_policy {
    zones = [var.zone_id]
  }
  deploy_policy {
    max_unavailable = 1
    max_expansion   = 0
  }
}


#----inventory for Ansible-----
output "instance_ips" {
  value = yandex_compute_instance_group.ig-a.instances[*].network_interface[0].nat_ip_address
}

resource "local_file" "inventory" {
  filename = "../ansible/inventory.ini"

  content = <<EOF
[webservers]
%{ for ip in yandex_compute_instance_group.ig-a.instances[*].network_interface[0].nat_ip_address }
${ip}
%{ endfor }
EOF

  depends_on = [yandex_compute_instance_group.ig-a]
}


#------App Load Balancer -------
output "vm_1_ip" {
  value = yandex_compute_instance_group.ig-a.instances[0].network_interface[0].ip_address
}

output "vm_2_ip" {
  value = yandex_compute_instance_group.ig-a.instances[1].network_interface[0].ip_address
}

resource "yandex_alb_target_group" "vhosting-tg-a" {
depends_on = [yandex_compute_instance_group.ig-a]
  name = "vhosting-tg-a"

  target {
    subnet_id  = yandex_vpc_subnet.subnet.id
    ip_address = yandex_compute_instance_group.ig-a.instances[0].network_interface[0].ip_address
  }

  target {
    subnet_id  = yandex_vpc_subnet.subnet.id
    ip_address = yandex_compute_instance_group.ig-a.instances[1].network_interface[0].ip_address
  }
}


resource "yandex_alb_backend_group" "vhosting-bg-a" {
depends_on = [yandex_alb_target_group.vhosting-tg-a]
  name = "vhosting-bg-a"
  http_backend {
    name = "vhosting-backend-a"
        port = 3000
        weight = 1
        target_group_ids = ["${yandex_alb_target_group.vhosting-tg-a.id}"]

        load_balancing_config {
          panic_threshold  = 0
          locality_aware_routing_percent = 0 
          mode = "ROUND_ROBIN"
        }

        healthcheck {
          timeout = "1s"
          interval = "1s"
          unhealthy_threshold = 1
          healthy_threshold = 1
          healthcheck_port = 3000
          http_healthcheck {
            path = "/"
          }
        }
  }
}



# Создание HTTP-роутера
resource "yandex_alb_http_router" "vhosting-router-a" {
  name          = "vhosting-router-a"
}


resource "yandex_alb_virtual_host" "vhosting-host-a" {
depends_on = [yandex_alb_http_router.vhosting-router-a,yandex_alb_backend_group.vhosting-bg-a]
  name           = "vhosting-host-a"
  http_router_id = yandex_alb_http_router.vhosting-router-a.id
#  authority = ["hexletlab.adizit.kz"]
  route {
    name  = "vhosting-route-a"
        http_route {
          http_route_action {
            backend_group_id = yandex_alb_backend_group.vhosting-bg-a.id
          }
        }
  }
}


data "yandex_vpc_address" "vhosting-ext-ip" {
  address_id = yandex_vpc_address.vhosting-ext-ip.id
}

output "vhosting-ext-ip" {
  value = data.yandex_vpc_address.vhosting-ext-ip.external_ipv4_address
}





resource "yandex_alb_load_balancer" "vhosting-alb" {
  name               = "vhosting-alb"
  network_id         = yandex_vpc_network.net.id
  security_group_ids = [yandex_vpc_security_group.sg-balancer.id]
  depends_on = [yandex_vpc_security_group.sg-balancer,yandex_alb_backend_group.vhosting-bg-a]


  allocation_policy {
    location {
      zone_id   = var.zone_id
      subnet_id = yandex_vpc_subnet.subnet.id
    }
  }

  listener {
    name  = "vhosting-listener-http"
    endpoint {
      address {
        external_ipv4_address {
          address = data.yandex_vpc_address.vhosting-ext-ip.external_ipv4_address[0].address
        }
      }
      ports  = [80]

    }
    http {
      redirects {
        http_to_https = true
      }
    }
  }

  listener {
    name  = "vhosting-listener-https"
    endpoint {
      address {
        external_ipv4_address {
          address = data.yandex_vpc_address.vhosting-ext-ip.external_ipv4_address[0].address
        }
      }
      ports  = [443]
    }
    tls {
      default_handler {
        http_handler {
          http_router_id = yandex_alb_http_router.vhosting-router-a.id
        }
        certificate_ids = [var.cert_id]
      }
      sni_handler {
        name         = "vhosting-sni-a"
        server_names = ["hexletlab.adizit.kz"]
        handler {
          http_handler {
            http_router_id = yandex_alb_http_router.vhosting-router-a.id
          }
          certificate_ids = [var.cert_id]
        }
      }
    }
  }
}


