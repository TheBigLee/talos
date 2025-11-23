output "control_plane_servers" {
  description = "Information about the control plane servers"
  value = [
    for server in hcloud_server.control_plane : {
      name       = server.name
      id         = server.id
      public_ip  = server.ipv4_address
      private_ip = [for net in server.network : net.ip][0]
      location   = server.location
    }
  ]
}

output "load_balancer" {
  description = "Load balancer information"
  value = {
    name      = hcloud_load_balancer.talos.name
    id        = hcloud_load_balancer.talos.id
    public_ip = hcloud_load_balancer.talos.ipv4
    targets   = hcloud_load_balancer.talos.target
  }
}

output "network" {
  description = "Network information"
  value = {
    name     = hcloud_network.talos.name
    id       = hcloud_network.talos.id
    ip_range = hcloud_network.talos.ip_range
  }
}

output "kubernetes_api_endpoint" {
  description = "Kubernetes API endpoint"
  value       = "${hcloud_load_balancer.talos.ipv4}:6443"
}

output "talos_api_endpoint" {
  description = "Talos API endpoint"
  value       = "${hcloud_load_balancer.talos.ipv4}:50000"
}
