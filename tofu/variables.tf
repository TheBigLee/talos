variable "cluster_name" {
  description = "Name of the Talos cluster"
  type        = string
  default     = "talos"
}

variable "server_type" {
  description = "Hetzner Cloud server type for control plane nodes"
  type        = string
  default     = "cx33"
}

variable "location" {
  description = "Hetzner Cloud location for all servers"
  type        = string
  default     = "nbg1"
}

variable "control_plane_count" {
  description = "Number of control plane servers"
  type        = number
  default     = 3
}

variable "network_ip_range" {
  description = "IP range for the private network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_ip_range" {
  description = "IP range for the subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "load_balancer_type" {
  description = "Hetzner Cloud load balancer type"
  type        = string
  default     = "lb11"
}

variable "kubernetes_api_port" {
  description = "Port for Kubernetes API"
  type        = number
  default     = 6443
}

variable "talos_api_port" {
  description = "Port for Talos API"
  type        = number
  default     = 50000
}

variable "traefik_http_port" {
  description = "Node-Port for traefik HTTP"
  type        = number
  default     = 30000
}

variable "traefik_https_port" {
  description = "Node-Port for traefik HTTPs"
  type        = number
  default     = 30001
}

variable "load_balancer_ip" {
  description = "Private IP for the load balancer"
  type        = string
  default     = "10.0.1.100"
}

variable "server_ip_start" {
  description = "Starting IP offset for servers (10.0.1.X)"
  type        = number
  default     = 10
}

variable "talos_snapshot_id" {
  description = "Hetzner Cloud snapshot ID for Talos OS"
  type        = number
  default     = 334760723
}
