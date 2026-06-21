resource "proxmox_virtual_environment_vm" "vm" {
  name      = var.vm_name
  node_name = var.proxmox_node
  vm_id     = var.vm_id

  agent {
    enabled = true
  }

  cpu {
    cores = var.cpu_cores
    type  = "host" # Passes host CPU capabilities including SME/SEV/SGX
  }

  memory {
    dedicated = var.memory_mb
  }

  network_device {
    bridge = var.vnet_id
  }

  disk {
    datastore_id = var.proxmox_storage
    file_format  = "raw"
    interface    = "scsi0"
    size         = 30
  }

  clone {
    # Uses VM ID 9000 for Ubuntu, 9001 for Windows, and 9002 for Alpine (matching Packer builds)
    vm_id = var.template_name == "ubuntu-22.04-golden-template" ? 9000 : (var.template_name == "alpine-golden-template" ? 9002 : 9001)
  }

  initialization {
    ip_config {
      ipv4 {
        address = var.ip_address
        gateway = var.gateway_ip
      }
    }

    dynamic "user_account" {
      for_each = var.ssh_key != "" ? [1] : []
      content {
        keys     = [var.ssh_key]
        username = "ubuntu"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      initialization[0].user_account[0].keys,
      network_device[0].mac_address
    ]
  }
}
