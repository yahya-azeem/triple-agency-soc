# Configure WinRM, Firewall, and preparation for sysprep and templating

Write-Host "=== Setting up WinRM ===" -ForegroundColor Green

# Enable WinRM service and configure network connection
winrm quickconfig -q
winrm quickconfig -transport:http -q

# Generate a self-signed certificate for the WinRM HTTPS listener
$cert = New-SelfSignedCertificate -DnsName "localhost" -CertStoreLocation "Cert:\LocalMachine\My"

# Enable WinRM listener over HTTPS
New-Item -Path WSMan:\localhost\Listener -Address * -Transport HTTPS -HostName "localhost" -CertificateThumbprint $cert.Thumbprint -Force

# Set WinRM settings to allow basic authentication for provisioning
Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value $false
Set-Item WSMan:\localhost\Service\Auth\Basic -Value $true

# Enable Firewall Rule for WinRM HTTPS (Port 5986)
New-NetFirewallRule -Name "WinRM_HTTPS" -DisplayName "Windows Remote Management (HTTPS-In)" -Description "Inbound rule for Windows Remote Management via WS-Management. [TCP 5986]" -Group "Windows Remote Management" -Program "System" -Protocol TCP -LocalPort 5986 -Action Allow -Enabled True

# Stop and disable Windows Update during template build (prevents hanging)
Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
Set-Service -Name wuauserv -StartupType Disabled

# Setup remote access and UAC settings
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "LocalAccountTokenFilterPolicy" -Value 1

# Install QEMU Guest Agent from VirtIO Drive
Write-Host "=== Installing QEMU Guest Agent ===" -ForegroundColor Green
$virtioVolume = Get-Volume | Where-Object {$_.FileSystemLabel -eq "virtio-win"}
if ($virtioVolume) {
    $driveLetter = $virtioVolume.DriveLetter
    $installerPath = Join-Path "${driveLetter}:" "guest-agent\qemu-ga-x86_64.msi"
    if (Test-Path $installerPath) {
        Start-Process msiexec.exe -ArgumentList "/i $installerPath /qn /norestart" -Wait
        Start-Service -Name "QEMU-GA" -ErrorAction SilentlyContinue
        Set-Service -Name "QEMU-GA" -StartupType Automatic
    }
}

# Run sysprep / generalize / oobe before shut down to make the VM a template
# Note: Packer does this natively if we run command at build stage or we can run sysprep at the very end
Write-Host "=== Preparation Complete ===" -ForegroundColor Green
