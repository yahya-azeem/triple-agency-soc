output "vm_id" {
  value       = proxmox_virtual_environment_vm.vm.vm_id
  description = "The VM ID of the deployed instance"
}

output "vm_ip" {
  value       = var.ip_address
  description = "The static IP assigned to the VM"
}

output "vm_name" {
  value       = proxmox_virtual_environment_vm.vm.name
  description = "The name of the VM"
}
