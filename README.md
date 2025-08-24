# Windows 11 Cloud PC with VNC - Docker Setup

A comprehensive Docker-based Windows cloud PC environment with VNC remote access, optimized for high-performance computing with NVIDIA GPU support.

## 🖥️ System Specifications

- **Operating System**: Windows Server Core LTSC2022 (Windows 11 compatible)
- **CPU**: 16 cores
- **RAM**: 128 GB
- **GPU**: NVIDIA Tesla T4 with CUDA support
- **Storage**: 512 GB SSD
- **Remote Access**: VNC (port 5901) + RDP (port 3389)

## 📁 Project Structure

```
├── Dockerfile                 # Main container definition
├── docker-compose.yml        # Orchestration and hardware specs
├── cloudpc-config.xml        # XML configuration for cloud PC
├── vnc-config.ini            # VNC server configuration
├── configure-cloudpc.ps1     # PowerShell setup script
├── README.md                 # This documentation
├── data/                     # Persistent data volume
├── logs/                     # Application and system logs
└── config/                   # Configuration files
```

## 🚀 Quick Start

### Prerequisites

- Docker Desktop with Windows containers enabled
- NVIDIA Docker runtime (for GPU support)
- At least 16 GB free disk space
- Windows 10/11 or Windows Server host

### 1. Clone and Build

```bash
# Clone or download all files to your project directory
# Build the container
docker compose up --build -d
```

### 2. Connect via VNC

Once the container is running:

- **VNC Address**: `localhost:5901`
- **Password**: `cloudpc123`
- **Alternative RDP**: `localhost:3389`

### 3. Monitor Status

```bash
# Check container status
docker compose ps

# View logs
docker compose logs -f windows-cloud-pc

# Check resource usage
docker stats windows11-cloudpc
```

## 🔧 Configuration Options

### Environment Variables

Edit [`docker-compose.yml`](docker-compose.yml) to customize:

```yaml
environment:
  - VNC_PASSWORD=your_password_here
  - VNC_PORT=5901
  - NVIDIA_VISIBLE_DEVICES=all
```

### Hardware Limits

Modify resource limits in [`docker-compose.yml`](docker-compose.yml):

```yaml
deploy:
  resources:
    limits:
      cpus: '16'        # Adjust CPU cores
      memory: 128G      # Adjust RAM
```

### XML Configuration

Edit [`cloudpc-config.xml`](cloudpc-config.xml) for advanced settings:

- Network ports and protocols
- Security policies
- Performance tuning
- Application auto-installation

## 🌐 Network Ports

| Port | Service | Description |
|------|---------|-------------|
| 5901 | VNC | Remote desktop access |
| 3389 | RDP | Windows Remote Desktop |
| 8080 | HTTP | Web interface |
| 8443 | HTTPS | Secure web interface |

## 🛠️ Advanced Usage

### Manual Configuration

Run the configuration script manually:

```powershell
# Inside the container
PowerShell -ExecutionPolicy Bypass -File "C:\CloudPC\scripts\configure-cloudpc.ps1" -VNCPassword "newpass" -CPUCores 8 -RAMSizeGB 64
```

### GPU Verification

Check NVIDIA GPU access:

```powershell
# Inside the container
nvidia-smi
```

### Performance Monitoring

```bash
# Real-time resource monitoring
docker exec -it windows11-cloudpc powershell "Get-Counter '\Processor(_Total)\% Processor Time'"
```

## 📊 Installed Applications

The container includes:

- **Browsers**: Firefox, Chrome
- **Development**: Git, Node.js, Python 3
- **Utilities**: 7zip, Notepad++
- **Runtimes**: .NET Runtime, Visual C++ Redistributables
- **GPU**: NVIDIA CUDA Toolkit

## 🔐 Security Features

- VNC password protection
- Windows Firewall configured
- Non-privileged container execution
- Isolated network namespace
- Resource limits enforcement

## 📈 Performance Optimization

### SSD Optimization
- Disk I/O optimizations configured
- Page file tuned for large RAM
- Windows services optimized

### VNC Performance
- Hardware acceleration enabled
- Polling optimizations
- Compression algorithms tuned

### GPU Acceleration
- NVIDIA Container Toolkit
- CUDA runtime support
- Hardware-accelerated rendering

## 🐛 Troubleshooting

### VNC Connection Issues

```bash
# Check if VNC service is running
docker exec -it windows11-cloudpc powershell "Get-Service tvnserver"

# View VNC logs
docker exec -it windows11-cloudpc type "C:\CloudPC\logs\vnc.log"
```

### Performance Issues

```bash
# Check resource usage
docker stats windows11-cloudpc

# View system logs
docker logs windows11-cloudpc
```

### GPU Not Detected

```bash
# Verify NVIDIA runtime
docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi

# Check container GPU access
docker exec -it windows11-cloudpc nvidia-smi
```

## 🔄 Management Commands

### Start/Stop Services

```bash
# Start container
docker compose up -d

# Stop container
docker compose down

# Restart container
docker compose restart
```

### Backup/Restore Data

```bash
# Backup data volume
docker run --rm -v cloudpc-data:/data -v $(pwd):/backup ubuntu tar czf /backup/cloudpc-backup.tar.gz -C /data .

# Restore data volume
docker run --rm -v cloudpc-data:/data -v $(pwd):/backup ubuntu tar xzf /backup/cloudpc-backup.tar.gz -C /data
```

## 📋 System Requirements

### Host System
- Windows 10/11 Professional or Enterprise
- Docker Desktop 4.0+
- NVIDIA drivers 470+
- 32 GB+ RAM recommended
- 100 GB+ free disk space

### Network Requirements
- Open ports 5901, 3389, 8080, 8443
- Stable internet connection for initial setup

## 🆘 Support and Logs

### Log Locations

| Component | Log Path |
|-----------|----------|
| VNC Server | `C:\CloudPC\logs\vnc.log` |
| System Monitor | `C:\CloudPC\logs\system-monitor.log` |
| Docker Logs | `docker logs windows11-cloudpc` |

### Common Issues

1. **Container fails to start**: Check Docker Windows container mode
2. **VNC connection refused**: Verify firewall rules and port mapping
3. **Poor performance**: Increase allocated CPU/RAM resources
4. **GPU not working**: Ensure NVIDIA Docker runtime is installed

## 📜 License and Usage

This configuration is designed for development and testing purposes. Ensure compliance with Microsoft Windows licensing terms when using in production environments.

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

---

**Note**: This setup provides a powerful Windows-based cloud PC environment suitable for development, testing, and remote work scenarios with high-performance computing requirements.