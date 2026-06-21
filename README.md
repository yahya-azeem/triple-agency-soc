# Elite Infrastructure as Code Security Operations Center (IaC SOC)

[![CI/CD Pipeline](https://img.shields.io/badge/CI%2FCD-GitLab--CI-orange?logo=gitlab)](.gitlab-ci.yml)
[![Infrastructure](https://img.shields.io/badge/Infrastructure-Terraform-blueviolet?logo=terraform)](terraform/)
[![Configuration](https://img.shields.io/badge/Configuration-Ansible-red?logo=ansible)](ansible/)
[![Detection](https://img.shields.io/badge/Detection-Sigma%20%2F%20KQL-blue)](detections/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

An agency-grade, automated Security Operations Center (SOC) home lab deployed programmatically from a single repository. Utilizing Zero Trust principles, Software-Defined Networking (SDN) EVPN-VXLAN overlays, mutual TLS (mTLS) cryptographic segmentation, DISA STIG continuous compliance scanning, Detection as Code, and automated adversary emulation.

---

## High-Level Topology

```
             [ WAN / Physical Bridge (vmbr0) ]
                           │
                 [ OPNsense Firewall VM ]
             (NAT / Inter-Tier Routing / DPI)
      ┌─────────────┬──────────────┬──────────────┐
      │             │              │              │
  [ Tier 0 ]    [ Tier 1 ]     [ Tier 2 ]     [ Tier 3 ]
  Mgmt / OOB    Core Services  Workloads      Sandbox / Dirty
  - SIEM / ELK  - Active Dir.  - Win Endpoints- Caldera C2
  - SOAR        - Step-CA      - Linux (Ubuntu)- Detonation
  - Monitor     - Vault        - Linux (Alpine)
```

---

## Core Technologies & Integrations

1. **Infrastructure Provisioning**: Terraform using the `bpg/proxmox` provider. Sets up EVPN software-defined network zones, subnets, and builds virtual machine instances based on Packer-generated Ubuntu 22.04, Alpine Linux, and Windows Server 2022 golden images.
2. **Network Segmentation**: Multi-tier network virtualization on Proxmox. Interfaces route through a virtualized OPNsense instance running Deep Packet Inspection (DPI) and enforcing default-deny traffic rules.
3. **Cryptographic Boundaries**: End-to-end mutual TLS (mTLS) implemented using HashiCorp Vault (offline Root CA) and Smallstep Step-CA (online Issuing CA with private ACME endpoints).
4. **Configuration Hardening**: Ansible playbooks implementing DISA STIG (Cat I & Cat II) security controls, OpenSCAP compliance scanning, and immutable `auditd` rules (`-e 2`).
5. **Detection as Code (DaC)**: Security detection rules authored in platform-agnostic Sigma format. Automatically compiled to Kibana Query Language (KQL) and deployed to the Elastic SIEM via rule APIs.
6. **Continuous Security Validation**: Automated attack simulations using MITRE Caldera and Atomic Red Team, triggered programmatically during the deployment pipeline.
7. **Automated Response (SOAR)**: Shuffle SOAR webhook workflows. Parses Elastic alerts and invokes Proxmox API scripts to dynamically shift compromised VM interfaces into the isolated Tier 3 Detonation VNet.

---

## Directory Structure

- [`terraform/`](file:///home/yahya/Projects/triple%20agency%20soc/terraform/): Declarative setup of network zones, firewalls, and VM topologies.
- [`packer/`](file:///home/yahya/Projects/triple%20agency%20soc/packer/): Automated builders for OS templates.
- [`ansible/`](file:///home/yahya/Projects/triple%20agency%20soc/ansible/): Playbooks and roles for hardening, monitoring agent deployment, and PKI certs setup.
- [`detections/`](file:///home/yahya/Projects/triple%20agency%20soc/detections/): Sigma rules repository, compiler scripts, and Elastic API integrations.
- [`threat-emulation/`](file:///home/yahya/Projects/triple%20agency%20soc/threat-emulation/): Caldera config, Atomic Red Team scripts, and AD vulnerability setup.
- [`soar/`](file:///home/yahya/Projects/triple%20agency%20soc/soar/): Shuffle workflow maps and Proxmox quarantine automation scripts.

---

## Quickstart Deployment Guide

### Prerequisites
- Proxmox VE Host installed with active SDN configuration enabled.
- OPNsense installation ISO loaded to storage.
- Python 3 and Git installed on the control machine.

### Installation Steps

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/triple-agency-soc.git
   cd triple-agency-soc
   ```

2. **Configure credentials**:
   Copy the example vars configuration and edit it to input your API credentials, token, nodes, and public SSH keys:
   ```bash
   cp terraform/terraform.tfvars.example terraform/terraform.tfvars
   nano terraform/terraform.tfvars
   ```

3. **Deploy the Infrastructure**:
   ```bash
   cd terraform
   terraform init
   terraform apply -auto-approve
   ```

4. **Run Configuration Playbooks**:
   ```bash
   cd ../ansible
   ansible-playbook playbooks/site.yml
   ```

5. **Verify Pipeline**:
   Commit rules or configuration changes, push to GitLab, and view the automated execution of the validation, deployment, compliance testing, threat simulation, and detection confirmation lifecycle.
