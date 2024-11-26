#------App Load Balancer -------

resource "yandex_alb_target_group" "vhosting-tg-a" {
depends_on = [yandex_compute_instance_group.ig-a]
  name = "vhosting-tg-a"

  target {
    subnet_id  = yandex_vpc_subnet.subnet.id
    ip_address = yandex_compute_instance_group.ig-a.instances[0].network_interface[0].ip_address
  }

#  target {
#    subnet_id  = yandex_vpc_subnet.subnet.id
#    ip_address = yandex_compute_instance_group.ig-a.instances[1].network_interface[0].ip_address
#  }
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
