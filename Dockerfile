# Windows 11 Cloud PC with VNC Access
# Base Windows Server Core image (Windows 11 containers not officially supported, using Windows Server as base)
FROM mcr.microsoft.com/windows/servercore:ltsc2022

# Set shell to PowerShell
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Set environment variables
ENV DISPLAY=:1 \
    VNC_PORT=5901 \
    VNC_PASSWORD=cloudpc123 \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=all

# Create working directory
WORKDIR C:\\CloudPC

# Install Chocolatey package manager
RUN Set-ExecutionPolicy Bypass -Scope Process -Force; \
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; \
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install essential packages
RUN choco install -y --no-progress \
    git \
    firefox \
    chrome \
    notepadplusplus \
    7zip \
    vcredist-all \
    dotnet-runtime \
    python3 \
    nodejs

# Install TightVNC Server
RUN Invoke-WebRequest -Uri 'https://www.tightvnc.com/download/2.8.27/tightvnc-2.8.27-gpl-setup-64bit.msi' -OutFile 'C:\\temp\\tightvnc-setup.msi'; \
    Start-Process -FilePath 'msiexec.exe' -ArgumentList '/i', 'C:\\temp\\tightvnc-setup.msi', '/quiet', '/norestart', 'ADDLOCAL=Server', 'SERVER_REGISTER_AS_SERVICE=1', 'SERVER_ADD_FIREWALL_EXCEPTION=1', 'SET_USEVNCAUTHENTICATION=1', 'VALUE_OF_USEVNCAUTHENTICATION=1', 'SET_PASSWORD=1', 'VALUE_OF_PASSWORD=cloudpc123', 'SET_USECONTROLAUTHENTICATION=1', 'VALUE_OF_USECONTROLAUTHENTICATION=1', 'SET_CONTROLPASSWORD=1', 'VALUE_OF_CONTROLPASSWORD=admin123' -Wait; \
    Remove-Item 'C:\\temp\\tightvnc-setup.msi'

# Configure Windows features and services
RUN Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole -All; \
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServer -All; \
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpCompressionStatic -All

# Install NVIDIA Container Toolkit (for GPU support)
RUN Invoke-WebRequest -Uri 'https://developer.download.nvidia.com/compute/cuda/repos/windows/x86_64/cuda-windows.exe' -OutFile 'C:\\temp\\cuda-installer.exe'; \
    Start-Process -FilePath 'C:\\temp\\cuda-installer.exe' -ArgumentList '/S' -Wait; \
    Remove-Item 'C:\\temp\\cuda-installer.exe'

# Create directories first
RUN New-Item -ItemType Directory -Force -Path 'C:\\CloudPC\\config'
RUN New-Item -ItemType Directory -Force -Path 'C:\\CloudPC\\scripts'
RUN New-Item -ItemType Directory -Force -Path 'C:\\CloudPC\\logs'
RUN New-Item -ItemType Directory -Force -Path 'C:\\CloudPC\\data'

# Copy configuration files
COPY configure-cloudpc.ps1 C:\\CloudPC\\scripts\\configure-cloudpc.ps1
COPY vnc-config.ini C:\\CloudPC\\config\\vnc-config.ini
COPY cloudpc-config.xml C:\\CloudPC\\config\\cloudpc-config.xml

# Execute configuration script
RUN PowerShell -ExecutionPolicy Bypass -Command "& 'C:\\CloudPC\\scripts\\configure-cloudpc.ps1' -VNCPassword (ConvertTo-SecureString 'cloudpc123' -AsPlainText -Force) -AdminPassword (ConvertTo-SecureString 'admin123' -AsPlainText -Force) -VNCPort 5901 -CPUCores 16 -RAMSizeGB 128"

# Set up VNC configuration
RUN New-Item -ItemType Directory -Force -Path 'C:\\Users\\ContainerAdministrator\\.vnc'; \
    Set-Content -Path 'C:\\Users\\ContainerAdministrator\\.vnc\\passwd' -Value (ConvertTo-SecureString -String 'cloudpc123' -AsPlainText -Force | ConvertFrom-SecureString)

# Configure registry for VNC and display settings
RUN New-ItemProperty -Path 'HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Terminal Server' -Name 'fDenyTSConnections' -Value 0 -PropertyType DWORD -Force; \
    New-ItemProperty -Path 'HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Terminal Server\\WinStations\\RDP-Tcp' -Name 'UserAuthentication' -Value 0 -PropertyType DWORD -Force

# Create startup script
RUN @' \
# VNC and Services Startup Script \
Write-Host "Starting Cloud PC Services..." \
Start-Service -Name "tvnserver" \
Start-Service -Name "W3SVC" \
Write-Host "Services started successfully" \
Write-Host "VNC Server running on port 5901" \
Write-Host "Use password: cloudpc123" \
# Keep container running \
while ($true) { Start-Sleep -Seconds 30; Write-Host "Cloud PC is running..." } \
'@ | Out-File -FilePath 'C:\\CloudPC\\startup.ps1' -Encoding ASCII

# Expose VNC port
EXPOSE 5901 3389 80 443

# Set resource limits and hardware specifications in labels
LABEL memory="137438953472" \
      cpus="16" \
      storage="549755813888" \
      gpu="nvidia-tesla-t4" \
      vnc.port="5901" \
      vnc.password="cloudpc123"

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD powershell -Command "try { Test-NetConnection -ComputerName localhost -Port 5901 -InformationLevel Quiet } catch { exit 1 }"

# Start the container with VNC server
CMD ["powershell", "-File", "C:\\CloudPC\\startup.ps1"]