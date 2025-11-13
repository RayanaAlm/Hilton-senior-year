"""
Main orchestrator that chains tools together.
"""

import json
from typing import Dict, List
from .tools.subfinder_wrapper import SubfinderWrapper
from .tools.dnsx_wrapper import DnsxWrapper
from .tools.gobuster_wrapper import GobusterWrapper


class Orchestrator:
    """Orchestrates multiple OSINT tools in sequence."""
    
    def __init__(self):
        """Initialize orchestrator with tool wrappers."""
        self.subfinder = SubfinderWrapper()
        self.dnsx = DnsxWrapper()
        self.gobuster = GobusterWrapper()
    
    def run_recon(self, domain: str, limit_gobuster: int = 3) -> Dict:
        """
        Run full reconnaissance on a domain.
        
        Args:
            domain: Target domain
            limit_gobuster: Limit number of URLs to scan with gobuster (for POC)
            
        Returns:
            Dictionary with all results
        """
        results = {
            "domain": domain,
            "subdomains": [],
            "resolved": [],
            "directories": [],
            "errors": []
        }
        
        # Step 1: Subfinder - Discover subdomains
        try:
            subdomains = self.subfinder.discover_subdomains(domain)
            results["subdomains"] = subdomains
        except Exception as e:
            results["errors"].append(f"Subfinder error: {str(e)}")
        
        # Step 2: Dnsx - Resolve subdomains
        try:
            if subdomains:
                resolved = self.dnsx.resolve_subdomains(subdomains)
                results["resolved"] = resolved
        except Exception as e:
            results["errors"].append(f"Dnsx error: {str(e)}")
        
        # Step 3: Gobuster - Discover directories (limit for POC)
        try:
            # Get first few resolved subdomains with IPs
            active_urls = []
            for item in results["resolved"][:limit_gobuster]:
                if item.get("resolved") and item.get("ips"):
                    subdomain = item["subdomain"]
                    # Try HTTP and HTTPS
                    for protocol in ["http", "https"]:
                        url = f"{protocol}://{subdomain}"
                        active_urls.append(url)
            
            # Run gobuster on limited URLs
            for url in active_urls[:limit_gobuster]:
                dirs = self.gobuster.discover_directories(url)
                results["directories"].extend(dirs)
        except Exception as e:
            results["errors"].append(f"Gobuster error: {str(e)}")
        
        return results
    
    def to_json(self, results: Dict) -> str:
        """
        Convert results to JSON string.
        
        Args:
            results: Results dictionary
            
        Returns:
            JSON string
        """
        return json.dumps(results, indent=2)

