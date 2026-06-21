#!/usr/bin/env python3
import os
import sys
import json
import urllib.request
import urllib.parse
import ssl

PVE_URL = os.environ.get("PVE_API_ENDPOINT", "https://10.10.0.10:8006/api2/json")
PVE_USER = os.environ.get("PVE_USER", "root@pam")
PVE_TOKEN = os.environ.get("PVE_API_TOKEN", "") # format: root@pam!token=secret

def make_pve_api_call(path, data=None, method="GET"):
    url = f"{PVE_URL}{path}"
    headers = {
        "Authorization": f"PVEAPIToken={PVE_TOKEN}",
        "Accept": "application/json",
        "Content-Type": "application/x-www-form-urlencoded"
    }
    
    encoded_data = None
    if data:
        encoded_data = urllib.parse.urlencode(data).encode("utf-8")
        
    req = urllib.request.Request(url, data=encoded_data, headers=headers, method=method)
    
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    
    try:
        with urllib.request.urlopen(req, context=ctx) as response:
            return json.loads(response.read().decode())
    except Exception as e:
        print(f"[ERROR] Proxmox API Call failed: {e}")
        sys.exit(1)

def quarantine_vm(node, vmid):
    print(f"Quarantining VM {vmid} on Proxmox Node {node}...")
    
    # 1. Fetch current network devices of the VM
    config_path = f"/nodes/{node}/qemu/{vmid}/config"
    config_res = make_pve_api_call(config_path)
    
    data = config_res.get("data", {})
    net_key = None
    for k in data.keys():
        if k.startswith("net"):
            net_key = k
            break
            
    if not net_key:
        print(f"[ERROR] No network device found on VM {vmid}")
        sys.exit(1)
        
    current_net_config = data[net_key]
    print(f"Current Net Config: {current_net_config}")
    
    # Parse MAC address and model from existing config, e.g. "virtio=AA:BB:CC:DD:EE:FF,bridge=tier2"
    # We replace bridge=tier2 with bridge=tier3 (the detonation/sandbox zone)
    parts = current_net_config.split(",")
    new_parts = []
    for part in parts:
        if part.startswith("bridge="):
            new_parts.append("bridge=tier3")
        else:
            new_parts.append(part)
            
    new_net_config = ",".join(new_parts)
    print(f"New Net Config: {new_net_config}")
    
    # 2. Apply the new config (shift interface to Tier 3 VNet)
    update_data = {
        net_key: new_net_config
    }
    
    update_res = make_pve_api_call(config_path, data=update_data, method="PUT")
    print(f"[SUCCESS] VM {vmid} successfully isolated to Tier 3 VNet. API Task ID: {update_res.get('data')}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: ./quarantine-vm.py <node> <vmid>")
        sys.exit(1)
        
    node_arg = sys.argv[1]
    vmid_arg = sys.argv[2]
    
    quarantine_vm(node_arg, vmid_arg)
