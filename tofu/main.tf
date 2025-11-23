terraform {
  required_version = ">= 1.0"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.47"
    }
    sops = {
      source  = "carlpett/sops"
      version = "~> 1.0"
    }
  }
}

data "sops_file" "secrets" {
  source_file = "secrets.sops.yaml"
}

provider "hcloud" {
  token = data.sops_file.secrets.data["hcloud_token"]
}


data "hcloud_image" "talos" {
  id = var.talos_snapshot_id
}

resource "hcloud_network" "talos" {
  name     = "${var.cluster_name}-network"
  ip_range = var.network_ip_range
}

resource "hcloud_network_subnet" "talos" {
  network_id   = hcloud_network.talos.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = var.subnet_ip_range
}

resource "hcloud_server" "control_plane" {
  count = var.control_plane_count

  name        = "${var.cluster_name}-cp${count.index + 1}"
  image       = data.hcloud_image.talos.id
  server_type = var.server_type
  location    = var.location
  
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  network {
    network_id = hcloud_network.talos.id
    ip         = "10.0.1.${var.server_ip_start + count.index}"
  }

  labels = {
    cluster = var.cluster_name
    role    = "control-plane"
    talos   = "true"
  }

  depends_on = [hcloud_network_subnet.talos]
}

resource "hcloud_load_balancer" "talos" {
  name               = "${var.cluster_name}-lb"
  load_balancer_type = var.load_balancer_type
  location           = var.location

  labels = {
    cluster = var.cluster_name
    talos   = "true"
  }
}

resource "hcloud_load_balancer_network" "talos" {
  load_balancer_id = hcloud_load_balancer.talos.id
  network_id       = hcloud_network.talos.id
  ip               = var.load_balancer_ip
}

resource "hcloud_load_balancer_target" "control_plane" {
  type             = "label_selector"
  load_balancer_id = hcloud_load_balancer.talos.id
  label_selector   = "cluster=${var.cluster_name},role=control-plane"
  use_private_ip   = true

  depends_on = [hcloud_load_balancer_network.talos]
}

resource "hcloud_load_balancer_service" "kubernetes_api" {
  load_balancer_id = hcloud_load_balancer.talos.id
  protocol         = "tcp"
  listen_port      = var.kubernetes_api_port
  destination_port = var.kubernetes_api_port

  health_check {
    protocol = "tcp"
    port     = var.kubernetes_api_port
    interval = 10
    timeout  = 5
    retries  = 3
  }
}

resource "hcloud_load_balancer_service" "talos_api" {
  load_balancer_id = hcloud_load_balancer.talos.id
  protocol         = "tcp"
  listen_port      = var.talos_api_port
  destination_port = var.talos_api_port

  health_check {
    protocol = "tcp"
    port     = var.talos_api_port
    interval = 10
    timeout  = 5
    retries  = 3
  }
}

resource "hcloud_load_balancer_service" "traefik_http" {
  load_balancer_id = hcloud_load_balancer.talos.id
  protocol         = "tcp"
  listen_port      = 80
  destination_port = var.traefik_http_port

  health_check {
    protocol = "tcp"
    port     = var.traefik_http_port
    interval = 10
    timeout  = 5
    retries  = 3
  }
}

resource "hcloud_load_balancer_service" "traefik_https" {
  load_balancer_id = hcloud_load_balancer.talos.id
  protocol         = "tcp"
  listen_port      = 443
  destination_port = var.traefik_https_port

  health_check {
    protocol = "tcp"
    port     = var.traefik_https_port
    interval = 10
    timeout  = 5
    retries  = 3
  }
}
