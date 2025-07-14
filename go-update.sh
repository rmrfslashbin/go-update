#!/bin/bash

set -e

SCRIPT_NAME="$(basename "$0")"
GO_DL_URL="https://go.dev/dl/"
INSTALL_DIR="/usr/local"
TEMP_DIR="/tmp"

detect_arch() {
    local uname_arch=$(uname -m)
    case "$uname_arch" in
        x86_64) echo "amd64" ;;
        aarch64) echo "arm64" ;;
        i686|i386) echo "386" ;;
        armv7l) echo "armv6l" ;;
        s390x) echo "s390x" ;;
        ppc64le) echo "ppc64le" ;;
        *) 
            echo "Error: Unsupported architecture: $uname_arch" >&2
            exit 1
            ;;
    esac
}

get_current_version() {
    if command -v go >/dev/null 2>&1; then
        go version | awk '{print $3}' | sed 's/^go//'
    else
        echo "none"
    fi
}

fetch_available_versions() {
    local arch="$1"
    local show_all="${2:-false}"
    
    local versions=$(curl -s "$GO_DL_URL" | grep -o "go[0-9]\+\.[0-9]\+\(\.[0-9]\+\)\?\.linux-$arch\.tar\.gz" | \
        sed 's/\.linux-'"$arch"'\.tar\.gz$//' | sed 's/^go//' | sort -V -r | uniq)
    
    if [ "$show_all" = "true" ]; then
        echo "$versions"
    else
        # Show only the latest patch version for each major.minor
        echo "$versions" | awk -F. '
        {
            major_minor = $1 "." $2
            if (!(major_minor in seen)) {
                seen[major_minor] = 1
                print $0
            }
        }'
    fi
}

get_latest_version() {
    local arch="$1"
    fetch_available_versions "$arch" | head -n 1
}

get_download_info() {
    local version="$1"
    local arch="$2"
    local filename="go${version}.linux-${arch}.tar.gz"
    
    local download_url="https://go.dev/dl/${filename}"
    local page_content=$(curl -s "$GO_DL_URL")
    
    # Extract checksum
    local checksum_line=$(echo "$page_content" | grep -A 20 "$filename" | grep -o "SHA256.*[a-f0-9]\{64\}")
    local checksum=$(echo "$checksum_line" | awk '{print $NF}')
    
    # Extract file size
    local size_line=$(echo "$page_content" | grep -A 5 "$filename" | grep -o "[0-9]\+MB\|[0-9]\+KB\|[0-9]\+\.[0-9]\+MB")
    local size=$(echo "$size_line" | head -n 1)
    
    echo "$download_url $checksum $size"
}

download_and_verify() {
    local download_url="$1"
    local expected_checksum="$2"
    local filename=$(basename "$download_url")
    local filepath="$TEMP_DIR/$filename"
    
    echo "Downloading $filename..."
    curl -L -o "$filepath" "$download_url"
    
    echo "Verifying checksum..."
    local actual_checksum=$(sha256sum "$filepath" | awk '{print $1}')
    
    if [ "$actual_checksum" != "$expected_checksum" ]; then
        echo "Error: Checksum mismatch!" >&2
        echo "Expected: $expected_checksum" >&2
        echo "Actual: $actual_checksum" >&2
        rm -f "$filepath"
        exit 1
    fi
    
    echo "$filepath"
}

install_go() {
    local version="$1"
    local arch="$2"
    
    echo "Installing Go $version for $arch..."
    
    local download_info=$(get_download_info "$version" "$arch")
    local download_url=$(echo "$download_info" | awk '{print $1}')
    local checksum=$(echo "$download_info" | awk '{print $2}')
    local size=$(echo "$download_info" | awk '{print $3}')
    
    if [ -z "$checksum" ]; then
        echo "Error: Could not find checksum for Go $version" >&2
        exit 1
    fi
    
    if [ -n "$size" ]; then
        echo "Download size: $size"
    fi
    
    local filepath=$(download_and_verify "$download_url" "$checksum")
    
    echo "Removing existing Go installation..."
    sudo rm -rf "$INSTALL_DIR/go"
    
    echo "Extracting Go $version..."
    sudo tar -C "$INSTALL_DIR" -xzf "$filepath"
    
    echo "Cleaning up..."
    rm -f "$filepath"
    
    echo "Verifying installation..."
    if "$INSTALL_DIR/go/bin/go" version >/dev/null 2>&1; then
        echo "✓ Go $version installed successfully!"
        echo "Current version: $("$INSTALL_DIR/go/bin/go" version)"
        
        if ! echo "$PATH" | grep -q "$INSTALL_DIR/go/bin"; then
            echo ""
            echo "Note: $INSTALL_DIR/go/bin is not in your PATH"
            echo "Add this to your ~/.profile or ~/.bashrc:"
            echo "export PATH=\$PATH:$INSTALL_DIR/go/bin"
        fi
    else
        echo "Error: Installation verification failed!" >&2
        exit 1
    fi
}

show_usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Check for and install Go updates on Linux systems.

OPTIONS:
    (no args)           Check for available updates
    --update            Install the latest Go version
    --list              List available Go versions (latest patch per major.minor)
    --list --all        List all available Go versions
    --install VERSION   Install a specific Go version
    --help              Show this help message

Examples:
    $SCRIPT_NAME                    # Check for updates
    $SCRIPT_NAME --update           # Install latest version
    $SCRIPT_NAME --list             # List latest versions per major.minor
    $SCRIPT_NAME --list --all       # List all available versions
    $SCRIPT_NAME --install 1.23.4   # Install Go 1.23.4

EOF
}

main() {
    local arch=$(detect_arch)
    local current_version=$(get_current_version)
    
    case "${1:-}" in
        ""|--check)
            echo "Current Go version: $current_version"
            echo "System architecture: $arch"
            echo "Checking for updates..."
            
            local latest_version=$(get_latest_version "$arch")
            echo "Latest Go version: $latest_version"
            
            if [ "$current_version" != "$latest_version" ]; then
                echo ""
                echo "Update available: $current_version → $latest_version"
                echo "Run '$SCRIPT_NAME --update' to install"
            else
                echo "✓ Go is up to date"
            fi
            ;;
        --update)
            local latest_version=$(get_latest_version "$arch")
            echo "Installing latest Go version: $latest_version"
            install_go "$latest_version" "$arch"
            ;;
        --list)
            local show_all="false"
            if [ "${2:-}" = "--all" ]; then
                show_all="true"
            fi
            
            if [ "$show_all" = "true" ]; then
                echo "All available Go versions for $arch:"
            else
                echo "Available Go versions for $arch (latest patch per major.minor):"
            fi
            echo ""
            
            fetch_available_versions "$arch" "$show_all" | while read -r version; do
                if [ "$version" = "$current_version" ]; then
                    printf "  %-10s (current)\n" "$version"
                else
                    # Get size info for display
                    local size_info=$(get_download_info "$version" "$arch" | awk '{print $3}')
                    if [ -n "$size_info" ]; then
                        printf "  %-10s (%s)\n" "$version" "$size_info"
                    else
                        printf "  %-10s\n" "$version"
                    fi
                fi
            done
            ;;
        --install)
            if [ -z "${2:-}" ]; then
                echo "Error: Version required for --install" >&2
                echo "Usage: $SCRIPT_NAME --install VERSION" >&2
                exit 1
            fi
            install_go "$2" "$arch"
            ;;
        --help|-h)
            show_usage
            ;;
        *)
            echo "Error: Unknown option: $1" >&2
            show_usage
            exit 1
            ;;
    esac
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi