# Multi-Platform Windows Cloud PC Deployment Script
# Supports: Docker CLI, Docker Desktop, Podman Desktop, Podman CLI
# Part 4: Universal Container Platform Support

param(
    [string]$Platform = "auto",  # auto, docker, docker-desktop, podman, podman-desktop
    [string]$WindowsVersion = "11l", # 11l, 10l, win11, win10 (11l=Win11 LTSC 4.7GB, 10l=Win10 LTSC 4.6GB)
    [switch]$Build,
    [switch]$Start,
    [switch]$Stop,
    [switch]$Status,
    [switch]$Help
)

# Windows Version Configuration
$WindowsVersions = @{
    "11l" = @{
        Name = "Windows 11 LTSC"
        Size = "4.7 GB"
        Dockerfile = "Dockerfile"
        ComposeFile = "docker-compose.yml"
        Recommended = $true
        Description = "Modern, Latest Features, Enhanced Security"
    }
    "10l" = @{
        Name = "Windows 10 LTSC"
        Size = "4.6 GB"
        Dockerfile = "Dockerfile-win10"
        ComposeFile = "docker-compose-win10.yml"
        Recommended = $false
        Description = "Stable, Legacy Compatible, Enterprise Ready"
    }
    "win11" = @{
        Name = "Windows 11 LTSC"
        Size = "4.7 GB"
        Dockerfile = "Dockerfile"
        ComposeFile = "docker-compose.yml"
        Recommended = $true
        Description = "Alias for 11l"
    }
    "win10" = @{
        Name = "Windows 10 LTSC"
        Size = "4.6 GB"
        Dockerfile = "Dockerfile-win10"
        ComposeFile = "docker-compose-win10.yml"
        Recommended = $false
        Description = "Alias for 10l"
    }
}

# Platform Detection and Configuration
$PlatformConfigs = @{
    "docker" = @{
        Name = "Docker CLI"
        ComposeCmd = "docker compose"
        BuildCmd = "docker build"
        RunCmd = "docker run"
        PsCmd = "docker ps"
        StatsCmd = "docker stats"
        Available = $false
    }
    "docker-desktop" = @{
        Name = "Docker Desktop"
        ComposeCmd = "docker compose"
        BuildCmd = "docker build"
        RunCmd = "docker run"
        PsCmd = "docker ps"
        StatsCmd = "docker stats"
        Available = $false
    }
    "podman" = @{
        Name = "Podman CLI"
        ComposeCmd = "podman-compose"
        BuildCmd = "podman build"
        RunCmd = "podman run"
        PsCmd = "podman ps"
        StatsCmd = "podman stats"
        Available = $false
    }
    "podman-desktop" = @{
        Name = "Podman Desktop"
        ComposeCmd = "podman-compose"
        BuildCmd = "podman build"
        RunCmd = "podman run"
        PsCmd = "podman ps"
        StatsCmd = "podman stats"
        Available = $false
    }
}

function Show-Help {
    Write-Host "🌟 Multi-Platform Windows Cloud PC Deployment" -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: .\deploy-multi-platform.ps1 [options]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Platform Options:" -ForegroundColor Green
    Write-Host "  -Platform auto           Auto-detect available platform"
    Write-Host "  -Platform docker         Use Docker CLI"
    Write-Host "  -Platform docker-desktop Use Docker Desktop"
    Write-Host "  -Platform podman         Use Podman CLI"
    Write-Host "  -Platform podman-desktop Use Podman Desktop"
    Write-Host ""
    Write-Host "Windows Version Options:" -ForegroundColor Green
    foreach ($version in $WindowsVersions.Keys | Sort-Object) {
        $info = $WindowsVersions[$version]
        $recommended = if ($info.Recommended) { " ⭐ RECOMMENDED" } else { "" }
        Write-Host "  -WindowsVersion $version" -ForegroundColor White -NoNewline
        Write-Host " -> $($info.Name) ($($info.Size))$recommended" -ForegroundColor Yellow
        Write-Host "                        $($info.Description)" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "Actions:" -ForegroundColor Green
    Write-Host "  -Build                   Build the container"
    Write-Host "  -Start                   Start the Cloud PC"
    Write-Host "  -Stop                    Stop the Cloud PC"
    Write-Host "  -Status                  Show status"
    Write-Host "  -Help                    Show this help"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  .\deploy-multi-platform.ps1 -Build -Start -WindowsVersion 11l  # Win11 LTSC 4.7GB"
    Write-Host "  .\deploy-multi-platform.ps1 -Build -Start -WindowsVersion 10l  # Win10 LTSC 4.6GB"
    Write-Host "  .\deploy-multi-platform.ps1 -Build -Platform docker -WindowsVersion 11l"
    Write-Host "  .\deploy-multi-platform.ps1 -Start -Platform podman -WindowsVersion 10l"
    Write-Host "  .\deploy-multi-platform.ps1 -Status"
}

function Test-PlatformAvailability {
    Write-Host "🔍 Detecting available container platforms..." -ForegroundColor Cyan
    
    # Test Docker CLI
    try {
        $dockerVersion = docker --version 2>$null
        if ($dockerVersion -and ($dockerVersion -match "Docker version")) {
            $PlatformConfigs["docker"].Available = $true
            Write-Host "  ✅ Docker CLI: $dockerVersion" -ForegroundColor Green
        }
    } catch {
        Write-Host "  ❌ Docker CLI: Not available" -ForegroundColor Red
    }
    
    # Test Docker Desktop (check for Docker Desktop specific features)
    try {
        $dockerInfo = docker info 2>$null
        if ($dockerInfo -and ($dockerInfo -match "Docker Desktop")) {
            $PlatformConfigs["docker-desktop"].Available = $true
            Write-Host "  ✅ Docker Desktop: Available" -ForegroundColor Green
        } elseif ($PlatformConfigs["docker"].Available) {
            # Fall back to Docker CLI if Docker is available but not Desktop
            Write-Host "  ⚠️  Docker Desktop: Using Docker CLI instead" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  ❌ Docker Desktop: Not available" -ForegroundColor Red
    }
    
    # Test Podman CLI
    try {
        $podmanVersion = podman --version 2>$null
        if ($podmanVersion -and ($podmanVersion -match "podman version")) {
            $PlatformConfigs["podman"].Available = $true
            Write-Host "  ✅ Podman CLI: $podmanVersion" -ForegroundColor Green
        }
    } catch {
        Write-Host "  ❌ Podman CLI: Not available" -ForegroundColor Red
    }
    
    # Test Podman Desktop
    try {
        $podmanDesktop = Get-Process "Podman Desktop" -ErrorAction SilentlyContinue
        if ($podmanDesktop -and $PlatformConfigs["podman"].Available) {
            $PlatformConfigs["podman-desktop"].Available = $true
            Write-Host "  ✅ Podman Desktop: Available" -ForegroundColor Green
        } else {
            Write-Host "  ❌ Podman Desktop: Not running or not available" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ❌ Podman Desktop: Not available" -ForegroundColor Red
    }
    
    # Test podman-compose
    if ($PlatformConfigs["podman"].Available) {
        try {
            $podmanCompose = podman-compose --version 2>$null
            if (-not $podmanCompose) {
                Write-Host "  ⚠️  podman-compose not found. Installing..." -ForegroundColor Yellow
                Write-Host "     Run: pip install podman-compose" -ForegroundColor Yellow
            } else {
                Write-Host "  ✅ podman-compose: $podmanCompose" -ForegroundColor Green
            }
        } catch {
            Write-Host "  ⚠️  podman-compose: May need installation" -ForegroundColor Yellow
        }
    }
}

function Select-Platform {
    param([string]$RequestedPlatform)
    
    if ($RequestedPlatform -eq "auto") {
        # Auto-select based on availability priority
        if ($PlatformConfigs["docker-desktop"].Available) {
            return "docker-desktop"
        } elseif ($PlatformConfigs["docker"].Available) {
            return "docker"
        } elseif ($PlatformConfigs["podman-desktop"].Available) {
            return "podman-desktop"
        } elseif ($PlatformConfigs["podman"].Available) {
            return "podman"
        } else {
            throw "No container platform available. Please install Docker or Podman."
        }
    } else {
        if (-not $PlatformConfigs[$RequestedPlatform].Available) {
            throw "Requested platform '$RequestedPlatform' is not available."
        }
        return $RequestedPlatform
    }
}

function Get-ComposeFile {
    param([string]$WindowsVer, [string]$PlatformType)
    
    # Get base compose file from version configuration
    $versionInfo = $WindowsVersions[$WindowsVer]
    if (-not $versionInfo) {
        throw "Unknown Windows version: $WindowsVer. Valid options: $($WindowsVersions.Keys -join ', ')"
    }
    
    $baseFile = $versionInfo.ComposeFile
    
    # Check if platform-specific compose file exists
    $platformFile = "docker-compose-$PlatformType.yml"
    if (Test-Path $platformFile) {
        return $platformFile
    }
    
    return $baseFile
}

function Get-DockerFile {
    param([string]$WindowsVer)
    
    # Get dockerfile from version configuration
    $versionInfo = $WindowsVersions[$WindowsVer]
    if (-not $versionInfo) {
        throw "Unknown Windows version: $WindowsVer. Valid options: $($WindowsVersions.Keys -join ', ')"
    }
    
    return $versionInfo.Dockerfile
}

function New-Container {
    param([string]$SelectedPlatform, [string]$WindowsVer)
    
    $config = $PlatformConfigs[$SelectedPlatform]
    $versionInfo = $WindowsVersions[$WindowsVer]
    $composeFile = Get-ComposeFile -WindowsVer $WindowsVer -PlatformType $SelectedPlatform
    $dockerfile = Get-DockerFile -WindowsVer $WindowsVer
    
    Write-Host "🔨 Building $($versionInfo.Name) ($($versionInfo.Size)) using $($config.Name)..." -ForegroundColor Green
    Write-Host "   Using compose file: $composeFile" -ForegroundColor Yellow
    Write-Host "   Using dockerfile: $dockerfile" -ForegroundColor Yellow
    
    try {
        if ($SelectedPlatform -like "*podman*") {
            # Podman-specific build
            if (Test-Path $composeFile) {
                & podman-compose -f $composeFile build --no-cache
            } else {
                & podman build -t "windows-cloudpc-$WindowsVer" -f $dockerfile .
            }
        } else {
            # Docker build
            & docker compose -f $composeFile build --no-cache
        }
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Build completed successfully!" -ForegroundColor Green
            Write-Host "   Container: $($versionInfo.Name) ($($versionInfo.Size))" -ForegroundColor Cyan
        } else {
            Write-Host "❌ Build failed!" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Build error: $_" -ForegroundColor Red
    }
}

function Start-Container {
    param([string]$SelectedPlatform, [string]$WindowsVer)
    
    $config = $PlatformConfigs[$SelectedPlatform]
    $composeFile = Get-ComposeFile -WindowsVer $WindowsVer -PlatformType $SelectedPlatform
    
    Write-Host "🚀 Starting Windows $WindowsVer Cloud PC using $($config.Name)..." -ForegroundColor Green
    
    try {
        if ($SelectedPlatform -like "*podman*") {
            & podman-compose -f $composeFile up -d
        } else {
            & docker compose -f $composeFile up -d
        }
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Cloud PC started successfully!" -ForegroundColor Green
            Show-ConnectionInfo
        } else {
            Write-Host "❌ Failed to start Cloud PC!" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Start error: $_" -ForegroundColor Red
    }
}

function Stop-Container {
    param([string]$SelectedPlatform, [string]$WindowsVer)
    
    $config = $PlatformConfigs[$SelectedPlatform]
    $composeFile = Get-ComposeFile -WindowsVer $WindowsVer -PlatformType $SelectedPlatform
    
    Write-Host "🛑 Stopping Windows $WindowsVer Cloud PC using $($config.Name)..." -ForegroundColor Yellow
    
    try {
        if ($SelectedPlatform -like "*podman*") {
            & podman-compose -f $composeFile down
        } else {
            & docker compose -f $composeFile down
        }
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Cloud PC stopped successfully!" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to stop Cloud PC!" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Stop error: $_" -ForegroundColor Red
    }
}

function Show-Status {
    param([string]$SelectedPlatform)
    
    $config = $PlatformConfigs[$SelectedPlatform]
    
    Write-Host "📊 Cloud PC Status ($($config.Name)):" -ForegroundColor Cyan
    
    try {
        if ($SelectedPlatform -like "*podman*") {
            Write-Host "Containers:" -ForegroundColor Yellow
            & podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
            Write-Host "`nResource Usage:" -ForegroundColor Yellow
            & podman stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
        } else {
            Write-Host "Containers:" -ForegroundColor Yellow
            & docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
            Write-Host "`nResource Usage:" -ForegroundColor Yellow
            & docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
        }
    } catch {
        Write-Host "❌ Status error: $_" -ForegroundColor Red
    }
}

function Show-ConnectionInfo {
    Write-Host ""
    Write-Host "🖥️  Connection Information:" -ForegroundColor Cyan
    Write-Host "─────────────────────────────" -ForegroundColor Cyan
    Write-Host "VNC Address:     localhost:5901" -ForegroundColor White
    Write-Host "VNC Password:    cloudpc123" -ForegroundColor White
    Write-Host "VNC Admin:       admin123" -ForegroundColor White
    Write-Host "RDP Address:     localhost:3389" -ForegroundColor White
    Write-Host "Web Interface:   http://localhost:8080" -ForegroundColor White
    Write-Host ""
    Write-Host "💡 Recommended VNC Clients:" -ForegroundColor Green
    Write-Host "   • TightVNC Viewer" -ForegroundColor White
    Write-Host "   • RealVNC Viewer" -ForegroundColor White
    Write-Host "   • Remote Desktop Connection (RDP)" -ForegroundColor White
    Write-Host ""
}

# Main Execution
if ($Help) {
    Show-Help
    exit 0
}

Write-Host "🌟 Multi-Platform Windows Cloud PC Deployment" -ForegroundColor Magenta
Write-Host "==============================================" -ForegroundColor Magenta
Write-Host ""

# Detect available platforms
Test-PlatformAvailability

# Select platform
try {
    $selectedPlatform = Select-Platform -RequestedPlatform $Platform
    $platformConfig = $PlatformConfigs[$selectedPlatform]
    
    $versionInfo = $WindowsVersions[$WindowsVersion]
    $recommended = if ($versionInfo.Recommended) { " ⭐" } else { "" }
    
    Write-Host "🎯 Selected Platform: $($platformConfig.Name)" -ForegroundColor Green
    Write-Host "🪟 Windows Version: $($versionInfo.Name) ($($versionInfo.Size))$recommended" -ForegroundColor Green
    Write-Host "   $($versionInfo.Description)" -ForegroundColor Gray
    Write-Host ""
} catch {
    Write-Host "❌ Platform Selection Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Available platforms:" -ForegroundColor Yellow
    foreach ($platform in $PlatformConfigs.Keys) {
        $status = if ($PlatformConfigs[$platform].Available) { "✅ Available" } else { "❌ Not Available" }
        Write-Host "  $platform : $status" -ForegroundColor White
    }
    exit 1
}

# Execute requested action
try {
    if ($Build) {
        New-Container -SelectedPlatform $selectedPlatform -WindowsVer $WindowsVersion
    } elseif ($Start) {
        Start-Container -SelectedPlatform $selectedPlatform -WindowsVer $WindowsVersion
    } elseif ($Stop) {
        Stop-Container -SelectedPlatform $selectedPlatform -WindowsVer $WindowsVersion
    } elseif ($Status) {
        Show-Status -SelectedPlatform $selectedPlatform
    } else {
        Write-Host "⚠️  No action specified. Use -Build, -Start, -Stop, -Status, or -Help" -ForegroundColor Yellow
        Show-Help
    }
} catch {
    Write-Host "⚠️  Execution Error: $_" -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "🌟 Multi-Platform Deployment Complete!" -ForegroundColor Magenta