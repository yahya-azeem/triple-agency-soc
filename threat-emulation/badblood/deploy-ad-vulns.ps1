# PowerShell script to deploy vulnerable domain structures in Active Directory (Kerberoasting, AS-REP Roasting targets)

Import-Module ActiveDirectory -ErrorAction Stop

Write-Host "=== Setting up Vulnerable Active Directory Objects ===" -ForegroundColor Green

# 1. Setup AS-REP Roasting Target (Pre-authentication Not Required)
$userRoast = "roastable_user"
If (-not (Get-ADUser -Filter "SamAccountName -eq '$userRoast'")) {
    Write-Host "Creating user: $userRoast..."
    $pass = ConvertTo-SecureString "AgencySecurePass123!" -AsPlainText -Force
    New-ADUser -Name "AS-REP Roastable User" -SamAccountName $userRoast -UserPrincipalName "$userRoast@agency.internal" -AccountPassword $pass -Enabled $true
    
    # Disable Kerberos pre-authentication (DONT_REQ_PREAUTH flag)
    Set-ADUser $userRoast -DoesNotRequirePreAuth $true
    Write-Host "  [SUCCESS] Pre-authentication disabled for $userRoast"
}

# 2. Setup Kerberoasting Target (User Account with Service Principal Name)
$userKerb = "kerberoast_sql"
If (-not (Get-ADUser -Filter "SamAccountName -eq '$userKerb'")) {
    Write-Host "Creating user: $userKerb..."
    $pass = ConvertTo-SecureString "AgencySqlPass456!" -AsPlainText -Force
    New-ADUser -Name "SQL Server Service" -SamAccountName $userKerb -UserPrincipalName "$userKerb@agency.internal" -AccountPassword $pass -Enabled $true
    
    # Associate Service Principal Name (SPN) with the user account
    Set-ADUser $userKerb -ServicePrincipalNames @{Add="MSSQLSvc/db-srv.agency.internal:1433"}
    Write-Host "  [SUCCESS] Associated SPN MSSQLSvc/db-srv.agency.internal:1433 with $userKerb"
}

Write-Host "=== AD Vulnerabilities deployed successfully ===" -ForegroundColor Green
