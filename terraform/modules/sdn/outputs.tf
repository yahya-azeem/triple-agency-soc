output "vnet_ids" {
  value = {
    tier0 = proxmox_virtual_environment_sdn_vnet.tier0.id
    tier1 = proxmox_virtual_environment_sdn_vnet.tier1.id
    tier2 = proxmox_virtual_environment_sdn_vnet.tier2.id
    tier3 = proxmox_virtual_environment_sdn_vnet.tier3.id
  }
  description = "A map of tier names to SDN VNet IDs"
}

output "zone_id" {
  value       = proxmox_virtual_environment_sdn_zone.evpn_zone.id
  description = "The ID of the EVPN Zone"
}
