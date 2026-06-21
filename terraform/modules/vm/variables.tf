variable "proxmox_node" {
  type        = string
  description = "Target Proxmox node where the VM will run"
}

variable "proxmox_storage" {
  type        = string
  description = "The Proxmox storage pool for VM disks"
}

variable "vm_name" {
  type        = string
  description = "The hostname and VM name"
}

variable "vm_id" {
  type        = number
  description = "The specific ID allocated to the VM (e.g. 100)"
}

variable "template_name" {
  type        = string
  description = "The name of the Packer template to clone"
}

variable "vnet_id" {
  type        = string
  description = "The target SDN VNet ID (bridge) to attach the VM interface to"
}

variable "ssh_key" {
  type        = string
  description = "Public key to inject via cloud-init (for Linux VMs)"
  default     = ""
}

variable "ip_address" {
  type        = string
  description = "Static IP Address with CIDR block (e.g. 10.10.0.50/24)"
}

variable "gateway_ip" {
  type        = string
  description = "IP address of the gateway (the OPNsense firewall interface)"
}

variable "cpu_cores" {
  type        = number
  description = "Number of CPU cores"
  default     = 2
}

variable "memory_mb" {
  type        = number
  description = "Allocated memory in MB"
  default     = 4096
}
