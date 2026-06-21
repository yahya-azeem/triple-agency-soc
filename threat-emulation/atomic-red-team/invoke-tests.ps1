# PowerShell script to run Atomic Red Team tests on Windows
Param(
    [string]$Technique
)

If ([string]::IsNullOrEmpty($Technique)) {
    Write-Host "Usage: .\invoke-tests.ps1 -Technique <T1558.003 | T1558.001>" -ForegroundColor Red
    Exit 1
}

Write-Host "=== Executing Windows Atomic Red Team: $Technique ===" -ForegroundColor Green

# Install Invoke-AtomicRedTeam if not already installed
If (-not (Get-Module -ListAvailable -Name Invoke-AtomicRedTeam)) {
    Write-Host "Installing Invoke-AtomicRedTeam..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Iex (IWR 'https://raw.githubusercontent.com/redcanaryco/invoke-atomicredteam/master/install-atomicredteam.ps1' -UseBasicParsing)
    Install-AtomicRedTeam -Force
}

# Run specific techniques
If ($Technique -eq "T1558.003") {
    Write-Host "Simulating Kerberoasting attack..."
    # Requesting kerberos tickets for Service Principal Names
    Add-Type -AssemblyName System.IdentityModel
    New-Object System.IdentityModel.Tokens.KerberosRequestorSecurityToken -ArgumentList "MSSQLSvc/db-srv.agency.internal:1433" -ErrorAction SilentlyContinue
} 
ElseIf ($Technique -eq "T1558.001") {
    Write-Host "Simulating Golden Ticket generation..."
    # Execute mimikatz commands or similar simulator commands if available
    # For safe portfolio simulation, we trigger the specific event log structures
    Write-EventLog -LogName Security -Source Microsoft-Windows-Security-Auditing -EventId 4769 -EntryType SuccessAudit -Message "A Kerberos service ticket was requested. Ticket Encryption Type: 0x17. Ticket Lifetime: 999999" -ErrorAction SilentlyContinue
}
Else {
    Invoke-AtomicTest $Technique -ShowDetails
}

Write-Host "=== Test Finished ===" -ForegroundColor Green
