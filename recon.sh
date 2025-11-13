#!/bin/bash

###############################################################################
# OSINT RECON Tool - Main Script
# Beautiful shell-based TUI for running reconnaissance
###############################################################################

# Colors using ANSI escape codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color
BOLD='\033[1m'

###############################################################################
# TUI Functions
###############################################################################

show_banner() {
    echo -e "${CYAN}${BOLD}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║              OSINT RECON Tool - POC                         ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

show_progress_bar() {
    local current=$1
    local total=$2
    local width=40
    local percent=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    # Use # for filled and - for empty (more compatible)
    printf "${CYAN}["
    if [ $filled -gt 0 ]; then
        printf "%${filled}s" | tr ' ' '#'
    fi
    if [ $empty -gt 0 ]; then
        printf "%${empty}s" | tr ' ' '-'
    fi
    printf "] ${percent}%%${NC}\n"
}

show_spinner() {
    local pid=$1
    local message=$2
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        i=$(((i + 1) % 10))
        printf "\r${CYAN}${spin:$i:1}${NC} $message"
        sleep 0.1
    done
    printf "\r${GREEN}[✓]${NC} $message\n"
}

show_status() {
    local status=$1
    local message=$2
    if [ "$status" = "ok" ]; then
        echo -e "${GREEN}[✓]${NC} $message"
    elif [ "$status" = "info" ]; then
        echo -e "${BLUE}[i]${NC} $message"
    elif [ "$status" = "step" ]; then
        echo -e "${MAGENTA}[→]${NC} $message"
    fi
}

show_panel() {
    local title=$1
    shift
    local content="$@"
    
    echo -e "${CYAN}┌────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${BOLD}${WHITE}$title${NC}"
    echo -e "${CYAN}├────────────────────────────────────────────────────────┤${NC}"
    echo -e "$content"
    echo -e "${CYAN}└────────────────────────────────────────────────────────┘${NC}"
}

###############################################################################
# Main Execution
###############################################################################

main() {
    # Check arguments
    if [ $# -lt 1 ]; then
        show_banner
        echo -e "${RED}Error: Domain required${NC}"
        echo ""
        echo -e "${BOLD}Usage:${NC} ${CYAN}./recon.sh <domain>${NC}"
        echo ""
        echo -e "${BOLD}Example:${NC} ${CYAN}./recon.sh example.com${NC}"
        echo ""
        exit 1
    fi
    
    DOMAIN=$1
    
    # Quick check if tools are available
    local missing_tools=()
    for tool in subfinder dnsx gobuster; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        show_banner
        echo -e "${YELLOW}Warning: Some tools are not installed:${NC} ${missing_tools[*]}"
        echo ""
        echo -e "${BOLD}To install all tools, run:${NC}"
        echo -e "  ${CYAN}./install_all.sh${NC}"
        echo ""
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
        echo ""
    fi
    clear
    show_banner
    
    echo -e "${BOLD}Target:${NC} ${CYAN}$DOMAIN${NC}"
    echo ""
    
    # Step 1: Subfinder
    echo -e "${MAGENTA}[1/3]${NC} ${BOLD}Running Subfinder...${NC}"
    show_status "step" "Discovering subdomains..."
    
    # Run Python script and capture output
    PYTHON_OUTPUT=$(python3 main.py "$DOMAIN" 2>&1)
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error running reconnaissance${NC}"
        echo "$PYTHON_OUTPUT"
        exit 1
    fi
    
    # Parse JSON output
    SUBDOMAINS_COUNT=$(echo "$PYTHON_OUTPUT" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data.get('subdomains', [])))" 2>/dev/null || echo "0")
    RESOLVED_COUNT=$(echo "$PYTHON_OUTPUT" | python3 -c "import sys, json; data=json.load(sys.stdin); resolved=[r for r in data.get('resolved', []) if r.get('resolved')]; print(len(resolved))" 2>/dev/null || echo "0")
    DIRS_COUNT=$(echo "$PYTHON_OUTPUT" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data.get('directories', [])))" 2>/dev/null || echo "0")
    
    show_progress_bar 100 100
    show_status "ok" "Found: $SUBDOMAINS_COUNT subdomains"
    echo ""
    
    # Step 2: Dnsx (already done in orchestrator)
    echo -e "${MAGENTA}[2/3]${NC} ${BOLD}Running Dnsx...${NC}"
    show_status "step" "Resolving subdomains..."
    show_progress_bar 100 100
    show_status "ok" "Resolved: $RESOLVED_COUNT active subdomains"
    echo ""
    
    # Step 3: Gobuster (already done in orchestrator)
    echo -e "${MAGENTA}[3/3]${NC} ${BOLD}Running Gobuster...${NC}"
    show_status "step" "Scanning directories..."
    show_progress_bar 100 100
    show_status "ok" "Found: $DIRS_COUNT directories"
    echo ""
    
    # Display results summary
    echo ""
    SUMMARY=$(cat <<EOF
${GREEN}Subdomains Found:${NC} $SUBDOMAINS_COUNT
${GREEN}Active Subdomains:${NC} $RESOLVED_COUNT
${GREEN}Directories Found:${NC} $DIRS_COUNT
EOF
)
    show_panel "Results Summary" "$SUMMARY"
    
    # Display detailed results
    echo ""
    echo -e "${BOLD}Detailed Results:${NC}"
    echo "$PYTHON_OUTPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print('\n${CYAN}Subdomains:${NC}')
    for sub in data.get('subdomains', [])[:10]:
        print(f'  • {sub}')
    if len(data.get('subdomains', [])) > 10:
        print(f'  ... and {len(data.get(\"subdomains\", [])) - 10} more')
    
    print('\n${CYAN}Resolved:${NC}')
    for item in data.get('resolved', [])[:5]:
        if item.get('resolved'):
            print(f'  • {item[\"subdomain\"]} → {\", \".join(item[\"ips\"][:3])}')
    
    print('\n${CYAN}Directories:${NC}')
    for dir_item in data.get('directories', [])[:5]:
        print(f'  • {dir_item.get(\"path\", \"\")} (Status: {dir_item.get(\"status\", \"\")})')
except:
    pass
" 2>/dev/null || echo "Error parsing results"
    
    echo ""
}

main "$@"

