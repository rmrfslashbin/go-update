# Go Update Script

A simple Bash script to check for and install Go updates on Linux systems. This script automatically detects your system architecture and provides an easy way to manage Go versions without package managers.

## Features

- 🔍 **Check for updates**: Compare your current Go version with the latest available
- 📋 **List versions**: View available Go versions (filtered or complete list)
- ⬇️ **Download & install**: Automatically download and install specific Go versions
- 🔐 **SHA256 verification**: All downloads are cryptographically verified
- 🏗️ **Multi-architecture**: Supports AMD64, ARM64, 386, ARMv6l, s390x, ppc64le
- 📦 **No dependencies**: Pure Bash script with standard Linux tools

## Installation

1. Clone this repository:
```bash
git clone <repository-url>
cd go-update
```

2. Make the script executable:
```bash
chmod +x go-update.sh
```

3. Ensure `/usr/local/go/bin` is in your PATH:
```bash
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc
```

## Usage

### Check for Updates
```bash
./go-update.sh
```
Shows your current Go version and checks if a newer version is available.

### List Available Versions
```bash
# Show latest patch version per major.minor (recommended)
./go-update.sh --list

# Show all available versions
./go-update.sh --list --all
```

### Install Latest Version
```bash
./go-update.sh --update
```

### Install Specific Version
```bash
./go-update.sh --install 1.23.4
```

### Show Help
```bash
./go-update.sh --help
```

## Examples

```bash
$ ./go-update.sh
Current Go version: 1.24.4
System architecture: arm64
Checking for updates...
Latest Go version: 1.24.5

Update available: 1.24.4 → 1.24.5
Run './go-update.sh --update' to install

$ ./go-update.sh --list
Available Go versions for arm64 (latest patch per major.minor):

  1.24.5     
  1.23.11    
  1.22.12    
  1.21.13    
  1.20.14    

$ ./go-update.sh --update
Installing Go 1.24.5 for arm64...
Download size: 71MB
Downloading go1.24.5.linux-arm64.tar.gz...
Verifying checksum...
Removing existing Go installation...
Extracting Go 1.24.5...
Cleaning up...
Verifying installation...
✓ Go 1.24.5 installed successfully!
```

## Requirements

- Linux operating system
- `curl` for downloading
- `sudo` access for installation to `/usr/local/go`
- Standard Linux utilities: `grep`, `sed`, `awk`, `tar`, `sha256sum`

## Architecture Support

The script automatically detects your system architecture and downloads the appropriate Go binary:

| System Architecture | Go Architecture |
|-------------------|----------------|
| x86_64           | amd64          |
| aarch64          | arm64          |
| i686, i386       | 386            |
| armv7l           | armv6l         |
| s390x            | s390x          |
| ppc64le          | ppc64le        |

## How It Works

1. **Detection**: Automatically detects your system architecture using `uname -m`
2. **Fetching**: Scrapes the official Go downloads page at https://go.dev/dl/
3. **Verification**: Downloads SHA256 checksums and verifies file integrity
4. **Installation**: Follows the official Go installation procedure:
   - Removes existing `/usr/local/go` directory
   - Extracts new Go version to `/usr/local/go`
   - Verifies the installation

## Security

- All downloads are verified with SHA256 checksums from go.dev
- Downloads are performed over HTTPS
- No elevated privileges required for checking versions
- `sudo` only used for actual installation to `/usr/local/go`

## Troubleshooting

### Permission Issues
Ensure you have `sudo` access for installation:
```bash
sudo -v
```

### PATH Issues
If `go` command is not found after installation, add Go to your PATH:
```bash
export PATH=$PATH:/usr/local/go/bin
```

### Network Issues
The script requires internet access to:
- Fetch version information from https://go.dev/dl/
- Download Go binaries

### Version Not Found
If a specific version isn't available for your architecture:
```bash
./go-update.sh --list --all  # Check available versions
```

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.