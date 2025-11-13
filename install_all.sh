#!/bin/bash

###############################################################################
# OSINT RECON Tool - One-Click Install & Setup
# Installs everything needed: Go, Subfinder, Dnsx, Gobuster
###############################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'

show_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║     OSINT RECON Tool - One-Click Installation            ║"
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
    elif [ "$status" = "step" ]; then
        echo -e "${MAGENTA}[→]${NC} $message"
    fi
}

show_progress() {
    local step=$1
    local total=$2
    local message=$3
    echo -e "${CYAN}[$step/$total]${NC} ${BOLD}$message${NC}"
}

# Step 1: Check/Install Go
install_go() {
    show_progress 1 4 "Checking Go installation..."
    
    if command -v go &> /dev/null; then
        GO_VERSION=$(go version | awk '{print $3}')
        show_status "ok" "Go is already installed: $GO_VERSION"
        return 0
    fi
    
    show_status "info" "Go is not installed. Installing..."
    
    # Try apt-get
    if command -v apt-get &> /dev/null; then
        show_status "step" "Installing Go via apt-get (requires sudo)..."
        if sudo apt-get update -qq && sudo apt-get install -y golang-go 2>&1 | grep -v "^\(Reading\|Building\|Get\|Selecting\)"; then
            if command -v go &> /dev/null; then
                show_status "ok" "Go installed successfully"
                return 0
            fi
        fi
    fi
    
    show_status "error" "Failed to install Go automatically"
    echo ""
    echo -e "${YELLOW}Please install Go manually:${NC}"
    echo "  sudo apt-get update && sudo apt-get install -y golang-go"
    echo ""
    echo -e "${YELLOW}Or visit: https://go.dev/doc/install${NC}"
    return 1
}

# Step 2: Setup Go environment
setup_go_env() {
    show_progress 2 4 "Setting up Go environment..."
    
    # Add Go bin to PATH if it exists
    if [ -d "$HOME/go/bin" ] && [[ ":$PATH:" != *":$HOME/go/bin:"* ]]; then
        export PATH="$HOME/go/bin:$PATH"
        if ! grep -q 'export PATH="$HOME/go/bin:$PATH"' ~/.bashrc 2>/dev/null; then
            echo 'export PATH="$HOME/go/bin:$PATH"' >> ~/.bashrc
            show_status "ok" "Added ~/go/bin to PATH"
        fi
    fi
    
    # Add /usr/local/go/bin if Go is installed there
    if [ -d "/usr/local/go/bin" ] && [[ ":$PATH:" != *":/usr/local/go/bin:"* ]]; then
        export PATH="$PATH:/usr/local/go/bin"
        if ! grep -q 'export PATH="$PATH:/usr/local/go/bin"' ~/.bashrc 2>/dev/null; then
            echo 'export PATH="$PATH:/usr/local/go/bin"' >> ~/.bashrc
            show_status "ok" "Added /usr/local/go/bin to PATH"
        fi
    fi
    
    show_status "ok" "Go environment configured"
}

# Step 3: Install OSINT tools
install_tools() {
    show_progress 3 4 "Installing OSINT tools..."
    
    if ! command -v go &> /dev/null; then
        show_status "error" "Go is required but not found"
        return 1
    fi
    
    local tools_installed=0
    local tools_total=3
    
    # Install Subfinder
    if command -v subfinder &> /dev/null; then
        show_status "ok" "Subfinder already installed"
        ((tools_installed++))
    else
        show_status "step" "Installing Subfinder..."
        if go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest 2>&1 | tail -1; then
            show_status "ok" "Subfinder installed"
            ((tools_installed++))
        else
            show_status "error" "Failed to install Subfinder"
        fi
    fi
    
    # Install Dnsx
    if command -v dnsx &> /dev/null; then
        show_status "ok" "Dnsx already installed"
        ((tools_installed++))
    else
        show_status "step" "Installing Dnsx..."
        if go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest 2>&1 | tail -1; then
            show_status "ok" "Dnsx installed"
            ((tools_installed++))
        else
            show_status "error" "Failed to install Dnsx"
        fi
    fi
    
    # Install Gobuster
    if command -v gobuster &> /dev/null; then
        show_status "ok" "Gobuster already installed"
        ((tools_installed++))
    else
        # Try apt-get first
        if command -v apt-get &> /dev/null && sudo -n true 2>/dev/null; then
            show_status "step" "Installing Gobuster via apt-get..."
            if sudo apt-get install -y gobuster 2>&1 | grep -v "^\(Reading\|Building\|Get\|Selecting\)"; then
                if command -v gobuster &> /dev/null; then
                    show_status "ok" "Gobuster installed via apt-get"
                    ((tools_installed++))
                fi
            fi
        fi
        
        # If apt-get didn't work, try Go
        if ! command -v gobuster &> /dev/null; then
            show_status "step" "Installing Gobuster via Go..."
            if go install github.com/OJ/gobuster/v3@latest 2>&1 | tail -1; then
                show_status "ok" "Gobuster installed"
                ((tools_installed++))
            else
                show_status "error" "Failed to install Gobuster"
            fi
        fi
    fi
    
    # Refresh PATH
    if [ -d "$HOME/go/bin" ]; then
        export PATH="$HOME/go/bin:$PATH"
    fi
    
    if [ $tools_installed -eq $tools_total ]; then
        return 0
    else
        show_status "warn" "Some tools may need PATH configuration"
        return 1
    fi
}

# Step 4: Verify installation
verify_installation() {
    show_progress 4 4 "Verifying installation..."
    echo ""
    
    local all_ok=true
    
    # Check Python
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
        show_status "ok" "Python: $PYTHON_VERSION"
    else
        show_status "error" "Python3 not found"
        all_ok=false
    fi
    
    # Check Go
    if command -v go &> /dev/null; then
        GO_VERSION=$(go version | awk '{print $3}')
        show_status "ok" "Go: $GO_VERSION"
    else
        show_status "error" "Go not found"
        all_ok=false
    fi
    
    # Check tools
    for tool in subfinder dnsx gobuster; do
        if command -v "$tool" &> /dev/null; then
            show_status "ok" "$tool: Found"
        else
            show_status "error" "$tool: Not found in PATH"
            all_ok=false
            echo -e "${YELLOW}  Try: export PATH=\"\$HOME/go/bin:\$PATH\"${NC}"
        fi
    done
    
    return $([ "$all_ok" = true ] && echo 0 || echo 1)
}

main() {
    show_banner
    
    echo -e "${BOLD}This script will install:${NC}"
    echo "  • Go programming language"
    echo "  • Subfinder (subdomain discovery)"
    echo "  • Dnsx (DNS resolution)"
    echo "  • Gobuster (directory brute-forcing)"
    echo ""
    echo -e "${YELLOW}Note: Some steps require sudo privileges${NC}"
    echo ""
    read -p "Press Enter to continue or Ctrl+C to cancel..."
    echo ""
    
    # Step 1: Install Go
    if ! install_go; then
        show_status "error" "Installation failed. Please install Go manually and run again."
        exit 1
    fi
    echo ""
    
    # Step 2: Setup Go environment
    setup_go_env
    echo ""
    
    # Step 3: Install tools
    if ! install_tools; then
        show_status "warn" "Some tools failed to install"
    fi
    echo ""
    
    # Step 4: Verify
    if verify_installation; then
        echo ""
        echo -e "${GREEN}${BOLD}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}${BOLD}║           Installation Complete!                            ║${NC}"
        echo -e "${GREEN}${BOLD}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        show_status "ok" "All tools installed successfully!"
        echo ""
        show_status "info" "You can now run: ${CYAN}${BOLD}./recon.sh <domain>${NC}"
        echo ""
        show_status "info" "Example: ${CYAN}./recon.sh example.com${NC}"
        echo ""
    else
        echo ""
        show_status "warn" "Installation completed with some issues"
        show_status "info" "You may need to:"
        echo "  1. Restart your terminal"
        echo "  2. Run: export PATH=\"\$HOME/go/bin:\$PATH\""
        echo "  3. Run: ./setup.sh to verify"
        echo ""
    fi
}

main

