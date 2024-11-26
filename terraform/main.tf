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
    - systemctl enable ssh
    - systemctl start ssh
EOF
    }
  }

  scale_policy {
    fixed_scale {
      size = 1
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
