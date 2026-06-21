# Deploy virtualized OPNsense Firewall VM on Proxmox VE
# Configured with multiple network devices to bridge and route between Tier 0-3 SDN networks and WAN

resource "proxmox_virtual_environment_vm" "firewall" {
  name      = "opnsense-firewall"
  node_name = var.proxmox_node
  vm_id     = 99

  cpu {
    cores = 4
    type  = "host"
  }

  memory {
    dedicated = 8192
  }

  # Interface 1: WAN (connected to physical host network interface bridge)
  network_device {
    bridge = "vmbr0"
  }

  # Interface 2: Tier 0 VNet (Management)
  network_device {
    bridge = var.vnet_ids["tier0"]
  }

  # Interface 3: Tier 1 VNet (Core Services)
  network_device {
    bridge = var.vnet_ids["tier1"]
  }

  # Interface 4: Tier 2 VNet (Workloads)
  network_device {
    bridge = var.vnet_ids["tier2"]
  }

  # Interface 5: Tier 3 VNet (Sandbox / Detonation)
  network_device {
    bridge = var.vnet_ids["tier3"]
  }

  disk {
    datastore_id = var.proxmox_storage
    file_format  = "raw"
    interface    = "scsi0"
    size         = 40
  }

  cdrom {
    enabled   = true
    file_id   = "local:iso/OPNsense-23.7-OpenSSL-dvd-amd64.iso"
    interface = "ide2"
  }
}
