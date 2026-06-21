# Software-Defined Networking (SDN) Configuration using BPG Provider

# Define the EVPN Zone for distributed L2/L3 overlay
resource "proxmox_virtual_environment_sdn_zone" "evpn_zone" {
  zone   = "evpnzone"
  type   = "evpn"
  nodes  = [var.proxmox_node]
  mtu    = 1450 # Accounts for 50-byte VXLAN encapsulation overhead

  # EVPN Specific settings (requires FRR package on host)
  ipam = "pve" # Built-in IPAM
}

# Tier 0 - Out-of-Band Management VNet
resource "proxmox_virtual_environment_sdn_vnet" "tier0" {
  vnet    = "tier0"
  zone    = proxmox_virtual_environment_sdn_zone.evpn_zone.id
  tag     = 1000
}

# Subnet for Tier 0
resource "proxmox_virtual_environment_sdn_subnet" "tier0_subnet" {
  subnet   = "10.10.0.0/24"
  vnet     = proxmox_virtual_environment_sdn_vnet.tier0.id
  gateway  = "10.10.0.1"
  dhcp_ranges = ["10.10.0.150-10.10.0.200"]
}

# Tier 1 - Core Infrastructure VNet
resource "proxmox_virtual_environment_sdn_vnet" "tier1" {
  vnet    = "tier1"
  zone    = proxmox_virtual_environment_sdn_zone.evpn_zone.id
  tag     = 1001
}

# Subnet for Tier 1
resource "proxmox_virtual_environment_sdn_subnet" "tier1_subnet" {
  subnet   = "10.10.10.0/24"
  vnet     = proxmox_virtual_environment_sdn_vnet.tier1.id
  gateway  = "10.10.10.1"
  dhcp_ranges = ["10.10.10.150-10.10.10.200"]
}

# Tier 2 - Production Workloads VNet
resource "proxmox_virtual_environment_sdn_vnet" "tier2" {
  vnet    = "tier2"
  zone    = proxmox_virtual_environment_sdn_zone.evpn_zone.id
  tag     = 1002
}

# Subnet for Tier 2
resource "proxmox_virtual_environment_sdn_subnet" "tier2_subnet" {
  subnet   = "10.10.20.0/24"
  vnet     = proxmox_virtual_environment_sdn_vnet.tier2.id
  gateway  = "10.10.20.1"
  dhcp_ranges = ["10.10.20.150-10.10.20.200"]
}

# Tier 3 - Sandbox / Dirty WAN (Detonation Zone) VNet
resource "proxmox_virtual_environment_sdn_vnet" "tier3" {
  vnet    = "tier3"
  zone    = proxmox_virtual_environment_sdn_zone.evpn_zone.id
  tag     = 1003
}

# Subnet for Tier 3
resource "proxmox_virtual_environment_sdn_subnet" "tier3_subnet" {
  subnet   = "10.10.30.0/24"
  vnet     = proxmox_virtual_environment_sdn_vnet.tier3.id
  gateway  = "10.10.30.1"
  dhcp_ranges = ["10.10.30.150-10.10.30.200"]
}
