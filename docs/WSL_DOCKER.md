# WSL & Docker Setup Guide

**Complete guide for Windows Subsystem for Linux and Docker Engine setup (no Docker Desktop required).**

---

## 🐧 WSL Installation

### Quick Install
```powershell
# Install WSL with default Ubuntu distribution
wsl --install

# Restart computer (required)
```

### Manual Installation
```powershell
# 1. Enable WSL feature
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

# 2. Enable Virtual Machine Platform
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# 3. Restart computer

# 4. Set WSL 2 as default
wsl --set-default-version 2

# 5. Install Ubuntu
wsl --install -d Ubuntu
```

### Verify Installation
```powershell
# Check WSL status
wsl --status

# List installed distributions
wsl --list --verbose

# Enter WSL
wsl
```

---

## 🐳 Docker in WSL (Native Docker Engine)

**Why use Docker Engine in WSL instead of Docker Desktop?**
- No license restrictions for commercial use
- Lighter weight (no GUI overhead)
- Native Linux Docker experience
- Full control over Docker daemon
- Works seamlessly with VS Code Docker extension

### Automated Installation
```powershell
# Use the provided script (recommended)
.\automation\Install-WSLDockerEnvironment.ps1 -Silent
```

### Manual Installation

#### 1. Update Ubuntu
```bash
# Inside WSL
sudo apt update
sudo apt upgrade -y
```

#### 2. Install Prerequisites
```bash
sudo apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
```

#### 3. Add Docker Repository
```bash
# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

#### 4. Install Docker Engine
```bash
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

#### 5. Configure Docker
```bash
# Start Docker service
sudo service docker start

# Add user to docker group (no sudo needed)
sudo usermod -aG docker $USER

# Apply group changes
newgrp docker

# Enable Docker to start automatically
sudo systemctl enable docker
```

#### 6. Test Docker
```bash
# Test Docker installation
docker run --rm hello-world

# Check versions
docker --version
docker compose --version
```

---

## 🔧 Configuration

### Configure Docker Daemon
```bash
# Create daemon configuration
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<EOF
{
  "hosts": ["unix:///var/run/docker.sock", "tcp://0.0.0.0:2375"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

# Restart Docker
sudo service docker restart
```

### Windows Integration
```powershell
# In PowerShell (Windows)
# Set DOCKER_HOST environment variable
[System.Environment]::SetEnvironmentVariable('DOCKER_HOST', 'tcp://localhost:2375', 'User')

# Restart PowerShell

# Test from Windows
docker ps
```

### VS Code Integration
Add to VS Code `settings.json`:
```json
{
    "docker.host": "tcp://localhost:2375"
}
```

---

## 🚀 Usage

### Basic Docker Commands
```bash
# Inside WSL or from Windows PowerShell (if configured)

# List containers
docker ps
docker ps -a

# List images
docker images

# Run container
docker run --rm hello-world
docker run -d -p 80:80 nginx

# Docker Compose
docker compose up -d
docker compose down
docker compose logs -f

# Clean up
docker system prune -a
```

### WSL Management
```powershell
# From Windows PowerShell

# Start WSL
wsl

# Shutdown WSL
wsl --shutdown

# Terminate specific distribution
wsl --terminate Ubuntu

# Export distribution
wsl --export Ubuntu C:\backup\ubuntu.tar

# Import distribution
wsl --import Ubuntu C:\WSL\Ubuntu C:\backup\ubuntu.tar

# Unregister distribution
wsl --unregister Ubuntu
```

---

## 🔍 Troubleshooting

### Docker Service Won't Start
```bash
# Check service status
sudo service docker status

# Start service manually
sudo service docker start

# Check for errors
sudo journalctl -u docker.service -n 50
```

### Permission Denied Error
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Apply changes
newgrp docker

# Or logout and login again
exit
wsl
```

### Cannot Connect from Windows
```powershell
# 1. Check DOCKER_HOST variable
$env:DOCKER_HOST

# 2. Verify Docker daemon is listening on TCP
# In WSL:
sudo netstat -tulpn | grep 2375

# 3. Test connection
docker ps

# 4. If fails, restart Docker in WSL
wsl sudo service docker restart
```

### WSL Won't Start
```powershell
# 1. Check WSL status
wsl --status

# 2. Update WSL
wsl --update

# 3. Restart WSL
wsl --shutdown
wsl

# 4. Check for Windows updates
# Settings → Windows Update
```

---

## 📊 Performance Tips

### Optimize WSL 2
Create `.wslconfig` in `%USERPROFILE%`:
```ini
[wsl2]
memory=4GB
processors=2
swap=2GB
localhostForwarding=true
```

### Docker Performance
```bash
# Limit Docker resources in daemon.json
sudo tee /etc/docker/daemon.json <<EOF
{
  "max-concurrent-downloads": 3,
  "max-concurrent-uploads": 3,
  "default-address-pools": [
    {
      "base": "172.17.0.0/16",
      "size": 24
    }
  ]
}
EOF

sudo service docker restart
```

---

## 🔐 Security

### Secure Docker Daemon
```bash
# Restrict TCP socket to localhost only
sudo tee /etc/docker/daemon.json <<EOF
{
  "hosts": ["unix:///var/run/docker.sock", "tcp://127.0.0.1:2375"]
}
EOF

sudo service docker restart
```

### Use TLS (Recommended for production)
```bash
# Generate certificates
mkdir -p ~/.docker
cd ~/.docker

# Create CA
openssl genrsa -out ca-key.pem 4096
openssl req -new -x509 -days 365 -key ca-key.pem -sha256 -out ca.pem

# Create server key and certificate
openssl genrsa -out server-key.pem 4096
openssl req -subj "/CN=localhost" -sha256 -new -key server-key.pem -out server.csr

# Sign certificate
echo subjectAltName = DNS:localhost,IP:127.0.0.1 >> extfile.cnf
echo extendedKeyUsage = serverAuth >> extfile.cnf
openssl x509 -req -days 365 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem -extfile extfile.cnf

# Configure Docker to use TLS
sudo tee /etc/docker/daemon.json <<EOF
{
  "hosts": ["unix:///var/run/docker.sock", "tcp://0.0.0.0:2376"],
  "tls": true,
  "tlscert": "/home/$USER/.docker/server-cert.pem",
  "tlskey": "/home/$USER/.docker/server-key.pem",
  "tlsverify": true,
  "tlscacert": "/home/$USER/.docker/ca.pem"
}
EOF

sudo service docker restart
```

---

## 📚 Additional Resources

### Official Documentation
- [WSL Documentation](https://docs.microsoft.com/en-us/windows/wsl/)
- [Docker Engine Documentation](https://docs.docker.com/engine/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

### Useful Commands
```bash
# WSL
wsl --help
wsl --status
wsl --list --online  # Available distributions

# Docker
docker --help
docker compose --help
docker system df     # Disk usage
docker stats         # Resource usage
```

---

## 🎯 Next Steps

1. ✅ Install WSL: `wsl --install`
2. ✅ Install Docker Engine (use script or manual)
3. ✅ Configure Windows integration
4. ✅ Test with `docker run --rm hello-world`
5. ⭐ Install VS Code Docker extension
6. ⭐ Configure Docker Compose for your projects

---

**For more help, see [Troubleshooting Guide](TROUBLESHOOTING.md)**
