# Interactive Windows Version Selector
# Part 5: Smart Version Selection with Size Information

Write-Host "🌟 Windows Cloud PC Version Selector" -ForegroundColor Magenta
Write-Host "====================================" -ForegroundColor Magenta
Write-Host ""

# Windows Version Options
$versions = @(
    @{
        Code = "11l"
        Name = "Windows 11 LTSC"
        Size = "4.7 GB"
        Recommended = $true
        Description = "Modern UI, Latest Features, Enhanced Security, DirectX 12"
        UseCase = "New projects, Modern apps, Maximum security"
        Color = "Green"
    },
    @{
        Code = "10l" 
        Name = "Windows 10 LTSC"
        Size = "4.6 GB"
        Recommended = $false
        Description = "Stable Platform, Legacy Support, Enterprise Ready"
        UseCase = "Legacy apps, Enterprise environments, Resource constraints"
        Color = "Yellow"
    }
)

# Display version options
Write-Host "📋 Available Windows Versions:" -ForegroundColor Cyan
Write-Host ""

for ($i = 0; $i -lt $versions.Count; $i++) {
    $version = $versions[$i]
    $number = $i + 1
    $recommended = if ($version.Recommended) { " ⭐ RECOMMENDED" } else { "" }
    
    Write-Host "[$number] " -ForegroundColor White -NoNewline
    Write-Host "$($version.Name)" -ForegroundColor $version.Color -NoNewline
    Write-Host " ($($version.Size))$recommended" -ForegroundColor Cyan
    Write-Host "    Code: $($version.Code)" -ForegroundColor Gray
    Write-Host "    $($version.Description)" -ForegroundColor Gray
    Write-Host "    Best for: $($version.UseCase)" -ForegroundColor DarkGray
    Write-Host ""
}

# Get user selection
do {
    Write-Host "🎯 Select Windows Version [1-$($versions.Count)] or [Q]uit: " -ForegroundColor Yellow -NoNewline
    $selection = Read-Host
    
    if ($selection.ToLower() -eq 'q') {
        Write-Host "❌ Selection cancelled." -ForegroundColor Red
        exit 0
    }
    
    $selectionNumber = 0
    $isValidNumber = [int]::TryParse($selection, [ref]$selectionNumber)
    
    if ($isValidNumber -and $selectionNumber -ge 1 -and $selectionNumber -le $versions.Count) {
        $selectedVersion = $versions[$selectionNumber - 1]
        break
    } else {
        Write-Host "❌ Invalid selection. Please enter a number between 1 and $($versions.Count), or Q to quit." -ForegroundColor Red
        Write-Host ""
    }
} while ($true)

# Confirm selection
Write-Host ""
Write-Host "✅ Selected Version:" -ForegroundColor Green
Write-Host "   $($selectedVersion.Name) ($($selectedVersion.Size))" -ForegroundColor Cyan
Write-Host "   Code: $($selectedVersion.Code)" -ForegroundColor White
Write-Host "   $($selectedVersion.Description)" -ForegroundColor Gray
Write-Host ""

# Platform selection
Write-Host "🔧 Platform Selection:" -ForegroundColor Cyan
Write-Host "[1] Auto-detect platform (Recommended)"
Write-Host "[2] Docker Desktop"
Write-Host "[3] Docker CLI"
Write-Host "[4] Podman Desktop"
Write-Host "[5] Podman CLI"
Write-Host ""

do {
    Write-Host "🎯 Select Platform [1-5] or [Q]uit: " -ForegroundColor Yellow -NoNewline
    $platformSelection = Read-Host
    
    if ($platformSelection.ToLower() -eq 'q') {
        Write-Host "❌ Platform selection cancelled." -ForegroundColor Red
        exit 0
    }
    
    $platformNumber = 0
    $isValidPlatform = [int]::TryParse($platformSelection, [ref]$platformNumber)
    
    if ($isValidPlatform -and $platformNumber -ge 1 -and $platformNumber -le 5) {
        $platformOptions = @("auto", "docker-desktop", "docker", "podman-desktop", "podman")
        $selectedPlatform = $platformOptions[$platformNumber - 1]
        break
    } else {
        Write-Host "❌ Invalid platform selection. Please enter a number between 1 and 5, or Q to quit." -ForegroundColor Red
        Write-Host ""
    }
} while ($true)

# Action selection
Write-Host ""
Write-Host "🚀 Action Selection:" -ForegroundColor Cyan
Write-Host "[1] Build and Start (Recommended)"
Write-Host "[2] Build Only"
Write-Host "[3] Start Only (if already built)"
Write-Host "[4] Show Status"
Write-Host ""

do {
    Write-Host "🎯 Select Action [1-4] or [Q]uit: " -ForegroundColor Yellow -NoNewline
    $actionSelection = Read-Host
    
    if ($actionSelection.ToLower() -eq 'q') {
        Write-Host "❌ Action selection cancelled." -ForegroundColor Red
        exit 0
    }
    
    $actionNumber = 0
    $isValidAction = [int]::TryParse($actionSelection, [ref]$actionNumber)
    
    if ($isValidAction -and $actionNumber -ge 1 -and $actionNumber -le 4) {
        break
    } else {
        Write-Host "❌ Invalid action selection. Please enter a number between 1 and 4, or Q to quit." -ForegroundColor Red
        Write-Host ""
    }
} while ($true)

# Build command based on selections
$command = ".\deploy-multi-platform.ps1"

switch ($actionNumber) {
    1 { $command += " -Build -Start" }
    2 { $command += " -Build" }
    3 { $command += " -Start" }
    4 { $command += " -Status" }
}

$command += " -Platform $selectedPlatform -WindowsVersion $($selectedVersion.Code)"

# Show final command and execute
Write-Host ""
Write-Host "🎯 Final Configuration:" -ForegroundColor Magenta
Write-Host "─────────────────────────" -ForegroundColor Magenta
Write-Host "Windows Version: $($selectedVersion.Name) ($($selectedVersion.Size))" -ForegroundColor Cyan
Write-Host "Platform: $selectedPlatform" -ForegroundColor Cyan
Write-Host "Action: " -ForegroundColor Cyan -NoNewline
switch ($actionNumber) {
    1 { Write-Host "Build and Start" -ForegroundColor Green }
    2 { Write-Host "Build Only" -ForegroundColor Yellow }
    3 { Write-Host "Start Only" -ForegroundColor Blue }
    4 { Write-Host "Show Status" -ForegroundColor Magenta }
}
Write-Host ""
Write-Host "Command: $command" -ForegroundColor Gray
Write-Host ""

# Confirmation
Write-Host "🚀 Execute this configuration? [Y/n]: " -ForegroundColor Green -NoNewline
$confirm = Read-Host

if ($confirm.ToLower() -ne 'n' -and $confirm.ToLower() -ne 'no') {
    Write-Host ""
    Write-Host "🌟 Executing Windows Cloud PC Deployment..." -ForegroundColor Magenta
    Write-Host "==========================================" -ForegroundColor Magenta
    Write-Host ""
    
    # Execute the command
    Invoke-Expression $command
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "🎉 Deployment completed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "🖥️  Connection Information:" -ForegroundColor Cyan
        Write-Host "─────────────────────────────" -ForegroundColor Cyan
        Write-Host "VNC Address:  localhost:5901" -ForegroundColor White
        Write-Host "VNC Password: cloudpc123" -ForegroundColor White
        Write-Host "RDP Address:  localhost:3389" -ForegroundColor White
        Write-Host ""
        Write-Host "💡 Use TightVNC Viewer or RealVNC to connect!" -ForegroundColor Yellow
    } else {
        Write-Host ""
        Write-Host "❌ Deployment encountered errors. Check the output above." -ForegroundColor Red
    }
} else {
    Write-Host "❌ Deployment cancelled by user." -ForegroundColor Red
}

Write-Host ""
Write-Host "🌟 Interactive Selection Complete!" -ForegroundColor Magenta