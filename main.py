#!/usr/bin/env python3
"""
Main entry point for OSINT RECON tool.
Called by recon.sh shell script.
"""

import sys
import json
from recon_tool.orchestrator import Orchestrator


def main():
    """Main function."""
    if len(sys.argv) < 2:
        print(json.dumps({"error": "Domain required"}))
        sys.exit(1)
    
    domain = sys.argv[1]
    limit_gobuster = int(sys.argv[2]) if len(sys.argv) > 2 else 3
    
    orchestrator = Orchestrator()
    results = orchestrator.run_recon(domain, limit_gobuster)
    
    # Output results as JSON for shell script to parse
    print(json.dumps(results))


if __name__ == "__main__":
    main()

