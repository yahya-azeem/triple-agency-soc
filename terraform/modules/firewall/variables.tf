variable "proxmox_node" {
  type        = string
  description = "Target Proxmox node for virtual firewall deployment"
}

variable "proxmox_storage" {
  type        = string
  description = "Target storage pool for the virtual firewall disk"
}

variable "vnet_ids" {
  type        = map(string)
  description = "Map of VNets to attach to the firewall interfaces"
}
