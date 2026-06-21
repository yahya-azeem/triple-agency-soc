variable "proxmox_api_endpoint" {
  type        = string
  description = "The Proxmox VE API endpoint URL (e.g. https://192.168.1.100:8006/api2/json)"
}

variable "proxmox_api_token" {
  type        = string
  description = "The Proxmox API Token ID and secret (format: username@realm!tokenid=secret)"
  sensitive   = true
}

variable "proxmox_node" {
  type        = string
  description = "The target Proxmox node to deploy resources on"
  default     = "pve"
}

variable "proxmox_storage" {
  type        = string
  description = "The target storage pool for virtual machine disks"
  default     = "local-lvm"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH Public Key to insert into provisioned VMs"
}

variable "domain_name" {
  type        = string
  description = "The internal domain name for Active Directory and local resolution"
  default     = "agency.internal"
}
