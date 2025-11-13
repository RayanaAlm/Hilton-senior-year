#!/bin/bash

###############################################################################
# OSINT RECON Tool - One-Click Runner
# Simple wrapper that runs recon.sh with better UX
###############################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_help() {
    echo -e "${CYAN}${BOLD}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║           OSINT RECON Tool - Quick Runner                  ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "${BOLD}Usage:${NC}"
    echo "  ./run_recon.sh <domain>"
    echo ""
    echo -e "${BOLD}Examples:${NC}"
    echo "  ./run_recon.sh example.com"
    echo "  ./run_recon.sh google.com"
    echo ""
    echo -e "${BOLD}Or use the main script directly:${NC}"
    echo "  ./recon.sh <domain>"
    echo ""
}

# Check if domain provided
if [ $# -lt 1 ]; then
    show_help
    exit 1
fi

# Check if recon.sh exists
if [ ! -f "$SCRIPT_DIR/recon.sh" ]; then
    echo -e "${RED}Error: recon.sh not found${NC}"
    exit 1
fi

# Run the main recon script
"$SCRIPT_DIR/recon.sh" "$@"

