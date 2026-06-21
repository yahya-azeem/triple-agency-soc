# Packer configuration for Windows Server 2022 Golden Image on Proxmox

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

source "proxmox-iso" "windows-2022" {
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_username
  password                 = var.proxmox_password
  insecure_skip_tls_verify = true

  node                 = var.proxmox_node
  vm_id                = 9001
  vm_name              = "windows-2022-golden"
  template_name        = "windows-2022-golden-template"
  template_description = "Windows Server 2022 base golden template built by Packer"

  # Need both Windows ISO and VirtIO drivers ISO
  iso_file = "local:iso/en-us_windows_server_2022_x64_dvd.iso"
  iso_storage_pool = "local"
  
  # Configure secondary CDROM for VirtIO drivers
  additional_iso_files {
    device           = "sata3"
    iso_file         = "local:iso/virtio-win.iso"
    iso_storage_pool = "local"
    unmount          = true
  }

  unmount_iso = true

  cores  = 4
  sockets = 1
  memory = 4096

  network_adapters {
    model    = "virtio"
    bridge   = "vmbr0"
    firewall = false
  }

  disks {
    disk_size         = "40G"
    format            = "raw"
    storage_pool      = var.proxmox_storage
    type              = "scsi"
  }

  scsi_controller = "virtio-scsi-pci"

  # Floppy files used for Autounattend.xml automation
  floppy_files = [
    "floppy/Autounattend.xml",
    "scripts/prepare-windows.ps1"
  ]

  # Set up communicator parameters
  communicator   = "winrm"
  winrm_username = "Administrator"
  winrm_password = "PackerPassword123!"
  winrm_use_ssl  = true
  winrm_insecure = true
  winrm_port     = 5986
  winrm_timeout  = "45m"
}

build {
  sources = ["source.proxmox-iso.windows-2022"]

  provisioner "powershell" {
    script = "scripts/prepare-windows.ps1"
  }
}
