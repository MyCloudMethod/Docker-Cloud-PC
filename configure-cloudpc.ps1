# Cloud PC Configuration Script
# Configures Windows environment for optimal VNC and remote access

param(
    [SecureString]$VNCPassword = (ConvertTo-SecureString "cloudpc123" -AsPlainText -Force),
    [SecureString]$AdminPassword = (ConvertTo-SecureString "admin123" -AsPlainText -Force),
    [int]$VNCPort = 5901,
    [int]$CPUCores = 16,
    [int]$RAMSizeGB = 128
)

# Convert SecureString parameters to plain text for use in script
$VNCPasswordPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($VNCPassword))
$AdminPasswordPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminPassword))

Write-Host "Configuring Cloud PC Environment..." -ForegroundColor Green

# Create necessary directories
$directories = @(
    "C:\CloudPC\logs",
    "C:\CloudPC\data",
    "C:\CloudPC\config",
    "C:\CloudPC\scripts",
    "C:\CloudPC\temp"
)

foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir
        Write-Host "Created directory: $dir" -ForegroundColor Yellow
    }
}

# Configure Windows for VNC optimization
Write-Host "Configuring Windows settings for VNC..." -ForegroundColor Cyan

# Disable Windows Defender real-time protection for performance
try {
    Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
    Write-Host "Disabled Windows Defender real-time monitoring" -ForegroundColor Yellow
} catch {
    Write-Host "Could not disable Windows Defender (may not be available in container)" -ForegroundColor Orange
}

# Configure power settings for high performance
try {
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c  # High Performance
    Write-Host "Set power plan to High Performance" -ForegroundColor Yellow
} catch {
    Write-Host "Could not set power plan (may not be available in container)" -ForegroundColor Orange
}

# Configure registry settings for VNC optimization
Write-Host "Configuring registry settings..." -ForegroundColor Cyan

# Terminal Services configuration
$registryPaths = @{
    "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" = @{
        "fDenyTSConnections" = 0
        "fSingleSessionPerUser" = 0
    }
    "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" = @{
        "UserAuthentication" = 0
        "SecurityLayer" = 0
        "fDisableCdm" = 0
    }
}

foreach ($path in $registryPaths.Keys) {
    if (!(Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
    }
    
    foreach ($property in $registryPaths[$path].Keys) {
        $value = $registryPaths[$path][$property]
        try {
            New-ItemProperty -Path $path -Name $property -Value $value -PropertyType DWORD -Force | Out-Null
            Write-Host "Set registry: $path\$property = $value" -ForegroundColor Green
        } catch {
            Write-Host "Failed to set registry: $path\$property" -ForegroundColor Red
        }
    }
}

# Configure firewall rules
Write-Host "Configuring Windows Firewall..." -ForegroundColor Cyan

$firewallRules = @(
    @{ Name = "VNC-TCP-In"; Port = $VNCPort; Protocol = "TCP"; Direction = "Inbound" }
    @{ Name = "RDP-TCP-In"; Port = 3389; Protocol = "TCP"; Direction = "Inbound" }
    @{ Name = "HTTP-TCP-In"; Port = 80; Protocol = "TCP"; Direction = "Inbound" }
    @{ Name = "HTTPS-TCP-In"; Port = 443; Protocol = "TCP"; Direction = "Inbound" }
)

foreach ($rule in $firewallRules) {
    try {
        New-NetFirewallRule -DisplayName $rule.Name -Direction $rule.Direction -Protocol $rule.Protocol -LocalPort $rule.Port -Action Allow -ErrorAction SilentlyContinue
        Write-Host "Created firewall rule: $($rule.Name) on port $($rule.Port)" -ForegroundColor Green
    } catch {
        Write-Host "Firewall rule may already exist: $($rule.Name)" -ForegroundColor Yellow
    }
}

# Configure VNC service
Write-Host "Configuring VNC Service..." -ForegroundColor Cyan

# VNC registry configuration
$vncRegPath = "HKLM:\SOFTWARE\TightVNC\Server"
if (!(Test-Path $vncRegPath)) {
    New-Item -Path $vncRegPath -Force | Out-Null
}

$vncSettings = @{
    "RfbPort" = $VNCPort
    "HttpPort" = 5800
    "AcceptRfbConnections" = 1
    "QueryConnect" = 0
    "LocalInputPriority" = 0
    "BlockRemoteInput" = 0
    "AlwaysShared" = 1
    "LogLevel" = 30
}

# Configure VNC Control/Admin Password
try {
    $vncControlRegPath = "HKLM:\SOFTWARE\TightVNC\Server"
    New-ItemProperty -Path $vncControlRegPath -Name "ControlPassword" -Value $AdminPasswordPlain -PropertyType String -Force | Out-Null
    Write-Host "Set VNC Control Password for administrative access" -ForegroundColor Green
} catch {
    Write-Host "Failed to set VNC Control Password" -ForegroundColor Red
}

foreach ($setting in $vncSettings.Keys) {
    try {
        New-ItemProperty -Path $vncRegPath -Name $setting -Value $vncSettings[$setting] -PropertyType DWORD -Force | Out-Null
        Write-Host "Set VNC setting: $setting = $($vncSettings[$setting])" -ForegroundColor Green
    } catch {
        Write-Host "Failed to set VNC setting: $setting" -ForegroundColor Red
    }
}

# Configure system performance settings
Write-Host "Configuring performance settings..." -ForegroundColor Cyan

# Set virtual memory for large RAM
try {
    $computerSystem = Get-WmiObject -Class Win32_ComputerSystem
    $computerSystem.AutomaticManagedPagefile = $false
    $computerSystem.Put() | Out-Null
    
    $pageFile = Get-WmiObject -Class Win32_PageFileSetting
    if ($pageFile) {
        $pageFile.Delete()
    }
    
    $newPageFile = ([WMIClass]"Win32_PageFileSetting").CreateInstance()
    $newPageFile.Name = "C:\pagefile.sys"
    $newPageFile.InitialSize = [int]($RAMSizeGB * 1024 * 0.5)  # 50% of RAM
    $newPageFile.MaximumSize = [int]($RAMSizeGB * 1024)        # 100% of RAM
    $newPageFile.Put() | Out-Null
    
    Write-Host "Configured virtual memory: Initial=$($newPageFile.InitialSize)MB, Max=$($newPageFile.MaximumSize)MB" -ForegroundColor Green
} catch {
    Write-Host "Could not configure virtual memory settings" -ForegroundColor Orange
}

# Create log rotation script
$logRotationScript = @"
# Log Rotation Script
Get-ChildItem "C:\CloudPC\logs\*.log" | Where-Object { `$_.LastWriteTime -lt (Get-Date).AddDays(-7) } | Remove-Item -Force
Get-ChildItem "C:\CloudPC\logs\*.log" | Where-Object { `$_.Length -gt 50MB } | ForEach-Object {
    Move-Item `$_.FullName "`$(`$_.FullName).old"
    New-Item -ItemType File -Path `$_.FullName -Force
}
"@

$logRotationScript | Out-File -FilePath "C:\CloudPC\scripts\rotate-logs.ps1" -Encoding ASCII

# Create system monitoring script
$monitoringScript = @"
# System Monitoring Script
while (`$true) {
    `$cpu = Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 1 | Select-Object -ExpandProperty CounterSamples | Select-Object -ExpandProperty CookedValue
    `$mem = Get-Counter '\Memory\Available MBytes' -SampleInterval 1 -MaxSamples 1 | Select-Object -ExpandProperty CounterSamples | Select-Object -ExpandProperty CookedValue
    
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    `$logEntry = "`$timestamp - CPU: `$([math]::Round(`$cpu, 2))%, Available Memory: `$([math]::Round(`$mem))MB"
    
    Write-Host `$logEntry
    Add-Content -Path "C:\CloudPC\logs\system-monitor.log" -Value `$logEntry
    
    Start-Sleep -Seconds 60
}
"@

$monitoringScript | Out-File -FilePath "C:\CloudPC\scripts\system-monitor.ps1" -Encoding ASCII

Write-Host "Cloud PC configuration completed successfully!" -ForegroundColor Green
Write-Host "VNC Server will be available on port $VNCPort" -ForegroundColor Cyan
Write-Host "Use password: $VNCPasswordPlain" -ForegroundColor Cyan
Write-Host "VNC Admin/Control password: $AdminPasswordPlain" -ForegroundColor Cyan
Write-Host "System configured for $CPUCores CPU cores and $RAMSizeGB GB RAM" -ForegroundColor Cyan