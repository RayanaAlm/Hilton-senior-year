#!/bin/bash

###############################################################################
# Go Installation Helper Script
# Helps install Go programming language
###############################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

show_banner() {
    echo -e "${CYAN}${BOLD}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║              Go Installation Helper                        ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

show_status() {
    local status=$1
    local message=$2
    if [ "$status" = "ok" ]; then
        echo -e "${GREEN}[✓]${NC} $message"
    elif [ "$status" = "error" ]; then
        echo -e "${RED}[✗]${NC} $message"
    elif [ "$status" = "info" ]; then
        echo -e "${BLUE}[i]${NC} $message"
    fi
}

main() {
    clear
    show_banner
    
    if command -v go &> /dev/null; then
        GO_VERSION=$(go version | awk '{print $3}')
        show_status "ok" "Go is already installed: $GO_VERSION"
        exit 0
    fi
    
    show_status "info" "Go is not installed"
    echo ""
    echo -e "${BOLD}Installation Methods:${NC}"
    echo ""
    echo -e "${CYAN}Method 1: Using apt-get (requires sudo)${NC}"
    echo "  sudo apt-get update"
    echo "  sudo apt-get install -y golang-go"
    echo ""
    echo -e "${CYAN}Method 2: Manual installation (recommended)${NC}"
    echo "  1. Visit: https://go.dev/doc/install"
    echo "  2. Download the latest Go binary for Linux"
    echo "  3. Extract to /usr/local (requires sudo) or ~/go"
    echo ""
    echo -e "${CYAN}Method 3: Quick install script${NC}"
    echo "  Run the following commands:"
    echo ""
    echo "  ARCH=\$(uname -m)"
    echo "  if [ \"\$ARCH\" = \"x86_64\" ]; then"
    echo "    ARCH=\"amd64\""
    echo "  elif [ \"\$ARCH\" = \"aarch64\" ]; then"
    echo "    ARCH=\"arm64\""
    echo "  fi"
    echo "  VERSION=\"1.21.5\""
    echo "  cd /tmp"
    echo "  wget https://go.dev/dl/go\${VERSION}.linux-\${ARCH}.tar.gz"
    echo "  sudo tar -C /usr/local -xzf go\${VERSION}.linux-\${ARCH}.tar.gz"
    echo "  echo 'export PATH=\$PATH:/usr/local/go/bin' >> ~/.bashrc"
    echo "  export PATH=\$PATH:/usr/local/go/bin"
    echo ""
    echo -e "${YELLOW}After installation, restart your terminal or run:${NC}"
    echo "  source ~/.bashrc"
    echo ""
}

main

