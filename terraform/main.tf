provider "proxmox" {
  endpoint  = var.proxmox_api_endpoint
  api_token = var.proxmox_api_token
  insecure  = true
}

# Deploy the SDN configuration (EVPN/VXLAN overlay, Zones, VNets, Subnets)
module "sdn" {
  source       = "./modules/sdn"
  proxmox_node = var.proxmox_node
}

# Deploy virtual OPNsense firewall VM (perimeter security + inter-tier routing)
module "firewall" {
  source          = "./modules/firewall"
  proxmox_node    = var.proxmox_node
  proxmox_storage = var.proxmox_storage
  vnet_ids        = module.sdn.vnet_ids
}

# Core Services VM (Step-CA, DNS, Vault)
module "core_services" {
  source          = "./modules/vm"
  proxmox_node    = var.proxmox_node
  proxmox_storage = var.proxmox_storage
  vm_name         = "core-services"
  vm_id           = 100
  template_name   = "ubuntu-22.04-golden-template"
  vnet_id         = module.sdn.vnet_ids["tier1"] # Core infrastructure subnet
  ssh_key         = var.ssh_public_key
  ip_address      = "10.10.10.10/24"
  gateway_ip      = "10.10.10.1" # OPNsense interface on Tier 1
  cpu_cores       = 2
  memory_mb       = 4096
}

# Active Directory Domain Controller
module "ad_controller" {
  source          = "./modules/vm"
  proxmox_node    = var.proxmox_node
  proxmox_storage = var.proxmox_storage
  vm_name         = "ad-dc"
  vm_id           = 101
  template_name   = "windows-2022-golden-template"
  vnet_id         = module.sdn.vnet_ids["tier1"] # Core infrastructure subnet
  ssh_key         = "" # cloud-init key injection not utilized on AD standard VM
  ip_address      = "10.10.10.100/24"
  gateway_ip      = "10.10.10.1"
  cpu_cores       = 4
  memory_mb       = 8192
}

# Target Linux Server (Standalone/Linux Target)
module "linux_target" {
  source          = "./modules/vm"
  proxmox_node    = var.proxmox_node
  proxmox_storage = var.proxmox_storage
  vm_name         = "linux-target"
  vm_id           = 200
  template_name   = "ubuntu-22.04-golden-template"
  vnet_id         = module.sdn.vnet_ids["tier2"] # Workloads subnet
  ssh_key         = var.ssh_public_key
  ip_address      = "10.10.20.10/24"
  gateway_ip      = "10.10.20.1" # OPNsense interface on Tier 2
  cpu_cores       = 2
  memory_mb       = 4096
}

# Target Alpine Linux Server (Ultra-lightweight Target)
module "alpine_target" {
  source          = "./modules/vm"
  proxmox_node    = var.proxmox_node
  proxmox_storage = var.proxmox_storage
  vm_name         = "alpine-target"
  vm_id           = 202
  template_name   = "alpine-golden-template"
  vnet_id         = module.sdn.vnet_ids["tier2"] # Workloads subnet
  ssh_key         = var.ssh_public_key
  ip_address      = "10.10.20.20/24"
  gateway_ip      = "10.10.20.1"
  cpu_cores       = 1
  memory_mb       = 1024
}

# Target Windows Endpoint (joined to AD)
module "windows_target" {
  source          = "./modules/vm"
  proxmox_node    = var.proxmox_node
  proxmox_storage = var.proxmox_storage
  vm_name         = "windows-target"
  vm_id           = 201
  template_name   = "windows-2022-golden-template"
  vnet_id         = module.sdn.vnet_ids["tier2"] # Workloads subnet
  ssh_key         = ""
  ip_address      = "10.10.20.100/24"
  gateway_ip      = "10.10.20.1"
  cpu_cores       = 2
  memory_mb       = 4096
}

# Log aggregator & SIEM Server (Elastic Security, Wazuh Manager)
module "siem_server" {
  source          = "./modules/vm"
  proxmox_node    = var.proxmox_node
  proxmox_storage = var.proxmox_storage
  vm_name         = "siem-server"
  vm_id           = 300
  template_name   = "ubuntu-22.04-golden-template"
  vnet_id         = module.sdn.vnet_ids["tier0"] # Management subnet
  ssh_key         = var.ssh_public_key
  ip_address      = "10.10.0.50/24"
  gateway_ip      = "10.10.0.1" # OPNsense interface on Tier 0
  cpu_cores       = 8
  memory_mb       = 32768
}

# Network Monitoring Node (Zeek, Suricata, Port Mirroring collector)
module "monitor_server" {
  source          = "./modules/vm"
  proxmox_node    = var.proxmox_node
  proxmox_storage = var.proxmox_storage
  vm_name         = "monitor-server"
  vm_id           = 301
  template_name   = "ubuntu-22.04-golden-template"
  vnet_id         = module.sdn.vnet_ids["tier0"] # Management network (primary interface)
  ssh_key         = var.ssh_public_key
  ip_address      = "10.10.0.60/24"
  gateway_ip      = "10.10.0.1"
  cpu_cores       = 4
  memory_mb       = 8192
}

# SOAR Automation & Caldera C2 VM
module "security_automation" {
  source          = "./modules/vm"
  proxmox_node    = var.proxmox_node
  proxmox_storage = var.proxmox_storage
  vm_name         = "secops-soar"
  vm_id           = 302
  template_name   = "ubuntu-22.04-golden-template"
  vnet_id         = module.sdn.vnet_ids["tier0"]
  ssh_key         = var.ssh_public_key
  ip_address      = "10.10.0.70/24"
  gateway_ip      = "10.10.0.1"
  cpu_cores       = 4
  memory_mb       = 8192
}
