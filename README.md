# OSINT RECON Tool

Automated reconnaissance tool that orchestrates Subfinder, Dnsx, and Gobuster to discover internet-facing assets.

## Installation

Run the one-click installer:

```bash
./install_all.sh
```

This will automatically install:
- Go programming language
- Subfinder (subdomain discovery)
- Dnsx (DNS resolution)
- Gobuster (directory brute-forcing)

## Usage

Run reconnaissance on any domain:

```bash
./run_recon.sh <domain>
```

**Examples:**
```bash
./run_recon.sh example.com
./run_recon.sh hackerone.com
```

## What It Does

1. **Subfinder** - Discovers subdomains
2. **Dnsx** - Resolves subdomains to IP addresses
3. **Gobuster** - Scans directories on active subdomains

Results are displayed with progress bars and formatted output.
