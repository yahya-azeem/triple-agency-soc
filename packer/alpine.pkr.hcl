# Packer configuration for Alpine Linux Golden Image on Proxmox

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

source "proxmox-iso" "alpine" {
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_username
  password                 = var.proxmox_password
  insecure_skip_tls_verify = true

  node                 = var.proxmox_node
  vm_id                = 9002
  vm_name              = "alpine-golden"
  template_name        = "alpine-golden-template"
  template_description = "Alpine Linux base golden template built by Packer"

  iso_file = "local:iso/alpine-standard-3.18.4-x86_64.iso"
  iso_storage_pool = "local"
  unmount_iso      = true

  cores  = 1
  sockets = 1
  memory = 1024

  network_adapters {
    model    = "virtio"
    bridge   = "vmbr0"
    firewall = false
  }

  disks {
    disk_size         = "10G"
    format            = "raw"
    storage_pool      = var.proxmox_storage
    type              = "scsi"
  }

  scsi_controller = "virtio-scsi-pci"

  # Unattended installation using Alpine setup-alpine answers file
  http_directory = "http"
  boot_command = [
    "root<enter><wait>",
    "ifconfig eth0 up && udhcpc -i eth0<enter><wait10>",
    "wget http://{{ .HTTPIP }}:{{ .HTTPPort }}/answers<enter><wait>",
    "setup-alpine -f answers<enter><wait10>",
    "packerpassword123!<enter><wait>",
    "packerpassword123!<enter><wait10>",
    "y<enter><wait20>",
    "reboot<enter>"
  ]

  ssh_username = "root"
  ssh_password = "packerpassword123!"
  ssh_timeout  = "15m"
}

build {
  sources = ["source.proxmox-iso.alpine"]

  provisioner "shell" {
    inline = [
      "apk update",
      "apk add qemu-guest-agent bash curl",
      "rc-update add qemu-guest-agent default",
      "echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config",
      "rc-service sshd restart"
    ]
  }
}
