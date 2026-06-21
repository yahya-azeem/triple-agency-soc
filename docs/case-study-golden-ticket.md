# Case Study: Active Directory Golden Ticket Detection & Auto-Quarantine

An end-to-end walkthrough of an emulated Active Directory Golden Ticket attack, telemetry collection, Sigma-based detection engineering, and automated response.

---

## 1. Threat Emulation (The Attack)

Using **Atomic Red Team** (technique `T1558.001`), the adversary simulates a Golden Ticket attack on the Windows endpoint (`windows-target`) to forge a Kerberos Ticket Granting Ticket (TGT).

### Execution Command
The following PowerShell command was executed to request an anomalous Kerberos ticket using RC4 encryption and a lifetime exceeding the standard domain policy (10 hours):

```powershell
# Execute T1558.001 simulated Golden Ticket request
Invoke-AtomicTest T1558.001 -TestNumbers 1
```

---

## 2. Telemetry Collection (The Log)

The Windows Security log and Sysmon capture the anomalous Kerberos service ticket request.
- **Log Source**: `Microsoft-Windows-Eventlog-Security`
- **Event ID**: `4769` (A Kerberos service ticket was requested)

### Raw Event JSON (Wazuh Ingestion)
```json
{
  "winlog": {
    "provider_name": "Microsoft-Windows-Security-Auditing",
    "event_id": "4769",
    "task": "Kerberos Service Ticket Operations",
    "level": "information",
    "computer_name": "windows-target.agency.internal",
    "event_data": {
      "TargetUserName": "Administrator",
      "TargetDomainName": "AGENCY.INTERNAL",
      "ServiceName": "krbtgt",
      "ServiceSid": "S-1-5-21-123456789-987654321-11111111-502",
      "TicketEncryptionType": "0x17",
      "TicketTicketLifetime": "270000",
      "IpAddress": "::1"
    }
  }
}
```

> [!NOTE]
> Key indicators of compromise in this event:
> - `TicketEncryptionType` is `0x17` (RC4-HMAC, which is weak/legacy and commonly used by Mimikatz to forge tickets).
> - `TicketTicketLifetime` is `270000` seconds (75 hours, exceeding the standard 10-hour domain default).

---

## 3. Detection Engineering (The Rule)

The following Sigma rule detects the forged ticket request. It has been synced automatically to the Elastic SIEM as a KQL alert rule:

```yaml
title: Active Directory Golden Ticket Detection
id: f45e6274-1234-4567-89ab-cdef01234567
status: experimental
description: Detects golden ticket usage by identifying Kerberos TGS requests with RC4 encryption (0x17) and long ticket lifetimes.
logsource:
  product: windows
  service: security
detection:
  selection_evt:
    EventID: 4769
  selection_fields:
    TicketEncryptionType: '0x17'
    TicketTicketLifetime: '0x2a300'
  condition: selection_evt and selection_fields
level: high
```

### Compiled Elastic KQL Query
```kql
winlog.event_id: 4769 AND winlog.event_data.TicketEncryptionType: "0x17" AND winlog.event_data.TicketTicketLifetime: "0x2a300"
```

---

## 4. Automated Response (The SOAR Workflow)

Once the rule triggers inside Elastic Security, it sends a webhook notification to **Shuffle SOAR**.

```
[ Elastic SIEM Alert ] ──( Webhook )──> [ Shuffle SOAR ]
                                               │
                                       ( Parse Host / VMID )
                                               │
                                       ( Execute SSH Action )
                                               │
                                               ▼
                                 [ quarantine-vm.py 201 pve ]
                                               │
                                     ( Proxmox API Modify )
                                               │
                                               ▼
                             [ Network bridge: tier2 ➔ tier3 ]
```

1. **Webhook Ingest**: Shuffle receives the payload containing the alert.
2. **Parsing**: The workflow extracts the hostname (`windows-target`) and resolves it to its Proxmox VM ID (`201`).
3. **Execution**: Shuffle executes the Proxmox quarantine script:
   ```bash
   /opt/soar/scripts/quarantine-vm.py pve 201
   ```
4. **Isolate**: The script calls the Proxmox API, editing the VM configuration to replace `bridge=tier2` (workloads network) with `bridge=tier3` (detonation sandbox zone). The compromised VM is immediately isolated from the domain network and active internet.

---

## 5. Verification & Portfolio Impact

This case study proves the end-to-end functionality of the Security Operations Center. It demonstrates a complete purple-team feedback loop:
- **Offensive action**: Atomic Red Team runs T1558.001.
- **Logging layer**: Sysmon maps indicators to logs.
- **Monitoring layer**: Wazuh ships logs to Elastic Security.
- **Detection layer**: KQL rule triggers on anomalous event properties.
- **Defensive action**: Shuffle SOAR uses Proxmox APIs to isolate the virtual network interface in seconds.
