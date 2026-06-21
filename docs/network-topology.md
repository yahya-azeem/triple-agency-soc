# Virtual Network Segmentation & Out-of-Band Port Mirroring

This document outlines the detailed configuration of Proxmox VE Software-Defined Networking (SDN) and Linux bridge interfaces used to achieve out-of-band network visibility.

## Network Tier Classifications

| Tier | Name | VNet | IP Subnet | Routing Isolation Rules |
| :--- | :--- | :--- | :--- | :--- |
| **Tier 0** | Out-of-Band Management | `tier0` | `10.10.0.0/24` | Ingress limited to Jump Box via mutual TLS. Outbound WAN blocked. |
| **Tier 1** | Core Infrastructure | `tier1` | `10.10.10.0/24` | Allowed only to receive explicit authentication queries from Tier 2. |
| **Tier 2** | Production Workloads | `tier2` | `10.10.20.0/24` | Heavily monitored for lateral movement. Controlled outbound WAN access. |
| **Tier 3** | Sandbox / Detonation | `tier3` | `10.10.30.0/24` | Complete isolation. Zero ingress/egress to other tiers. Dropped by OPNsense. |

---

## Out-of-Band Network Telemetry Mirroring

In physical enterprise networks, Network TAPs or Switch Port Analyzer (SPAN) ports mirror network packets to Intrusion Detection Systems (IDS). In a virtualized hypervisor, standard Linux bridges act as switches and utilize MAC address learning, meaning unicast traffic between two VMs is never forwarded to a third monitoring port.

To enable passive monitoring via Zeek and Suricata, this lab modifies the Proxmox SDN bridge configurations to operate in a "hub" mode, forcing them to flood all traffic to the monitoring collector VM interface.

### Bridge Configuration

Within the Proxmox host `/etc/network/interfaces` configuration, MAC learning is disabled on the target bridge interfaces by setting bridge ageing to zero (`bridge_ageing 0`) and disabling spanning tree protocol (`bridge_stp off`):

```text
# Proxmox host network interfaces patch
auto lnet2
iface lnet2 inet manual
        bridge-ports none
        bridge-stp off
        bridge-fd 0
        bridge_ageing 0
        # Forces bridge to flood all traversing unicast packets to all virtual ports
```

This configuration floods all packets sent between Tier 2 workloads (such as AD DC and target endpoints) to the virtual TAP port attached to the **Monitor Server**, allowing Zeek and Suricata to perform deep packet inspection out-of-band.

### Suricata Performance Optimization (eBPF)

Suricata utilizes AF_PACKET and eBPF filters to process flooded packets inside the Linux kernel, bypassing standard user-space processing overhead. This allows the i9 host to monitor multi-gigabit workloads without dropping frames:

```yaml
# suricata.yaml configuration segment
af-packet:
  - interface: eth1
    cluster-id: 99
    cluster-type: cluster_flow
    defrag: yes
    use-mmap: yes
    tpacket-v3: yes
    ring-size: 2048
```
