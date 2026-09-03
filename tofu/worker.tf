locals {
  worker_snapshot_id = var.worker_snapshot_id != null ? var.worker_snapshot_id : var.talos_snapshot_id
}

# Deliberately not data.hcloud_image.talos. hcloud_server.image is ForceNew, so
# sharing the control plane's image reference would mean that repointing
# var.talos_snapshot_id at a newer Talos snapshot for the worker's sake
# destroys and recreates talos-cp1/2/3.
data "hcloud_image" "talos_worker" {
  id = local.worker_snapshot_id
}

# Worker nodes.
#
# Deliberately a separate resource from hcloud_server.control_plane rather than
# a bump to var.control_plane_count. Sharing that count would put workers in the
# same count index space as the control plane, where changing the number of one
# can reindex - and therefore destroy and recreate - the other.
resource "hcloud_server" "worker" {
  count = var.worker_count

  name        = "${var.cluster_name}-w${count.index + 1}"
  image       = data.hcloud_image.talos_worker.id
  server_type = var.worker_server_type
  location    = var.location

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  network {
    network_id = hcloud_network.talos.id
    ip         = "10.0.1.${var.worker_ip_start + count.index}"
  }

  labels = {
    cluster = var.cluster_name
    role    = "worker"
    talos   = "true"
  }

  depends_on = [hcloud_network_subnet.talos]
}

output "worker_servers" {
  description = "Information about the worker servers"
  value = [
    for server in hcloud_server.worker : {
      name       = server.name
      id         = server.id
      public_ip  = server.ipv4_address
      private_ip = [for net in server.network : net.ip][0]
      location   = server.location
    }
  ]
}
