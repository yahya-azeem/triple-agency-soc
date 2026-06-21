# Packer configuration for Ubuntu 22.04 Golden Image on Proxmox

packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.2"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

variable "proxmox_url" {
  type    = string
  default = "https://127.0.0.1:8006/api2/json"
}

variable "proxmox_username" {
  type    = string
  default = "root@pam"
}

variable "proxmox_password" {
  type      = string
  sensitive = true
  default   = ""
}

variable "proxmox_node" {
  type    = string
  default = "pve"
}

variable "proxmox_storage" {
  type    = string
  default = "local-lvm"
}

source "proxmox-iso" "ubuntu-22-04" {
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_username
  password                 = var.proxmox_password
  insecure_skip_tls_verify = true

  node                 = var.proxmox_node
  vm_id                = 9000
  vm_name              = "ubuntu-22.04-golden"
  template_name        = "ubuntu-22.04-golden-template"
  template_description = "Ubuntu 22.04 base golden template built by Packer"

  iso_file = "local:iso/ubuntu-22.04.4-live-server-amd64.iso"
  iso_storage_pool = "local"
  unmount_iso      = true

  cores  = 2
  sockets = 1
  memory = 2048

  network_adapters {
    model    = "virtio"
    bridge   = "vmbr0"
    firewall = false
  }

  disks {
    disk_size         = "20G"
    format            = "raw"
    storage_pool      = var.proxmox_storage
    type              = "scsi"
  }

  scsi_controller = "virtio-scsi-pci"

  # Cloud-init automatic installation (Autoinstall)
  http_directory = "http"
  boot_command = [
    "<esc><wait>",
    "c<wait>",
    "linux /casper/vmlinuz --- autoinstall ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/",
    "<enter><wait>",
    "initrd /casper/initrd",
    "<enter><wait>",
    "boot<enter>"
  ]

  ssh_username = "packer"
  ssh_password = "packerpassword123!"
  ssh_timeout  = "20m"
}

build {
  sources = ["source.proxmox-iso.ubuntu-22-04"]

  provisioner "shell" {
    script = "scripts/prepare-ubuntu.sh"
  }
}
