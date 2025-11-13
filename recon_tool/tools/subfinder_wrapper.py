"""
Subfinder wrapper for subdomain discovery.
"""

from .base_tool import BaseTool
from typing import List


class SubfinderWrapper(BaseTool):
    """Wrapper for Subfinder subdomain enumeration tool."""
    
    def __init__(self):
        """Initialize Subfinder wrapper."""
        super().__init__("subfinder")
    
    def discover_subdomains(self, domain: str) -> List[str]:
        """
        Discover subdomains for a given domain.
        
        Args:
            domain: Target domain
            
        Returns:
            List of discovered subdomains
        """
        if not self.available:
            return []
        
        # Execute: subfinder -d <domain> -silent
        command = ["subfinder", "-d", domain, "-silent"]
        stdout, stderr, returncode = self.execute(command, timeout=300)
        
        if returncode != 0:
            return []
        
        # Parse output (one subdomain per line)
        subdomains = [line.strip() for line in stdout.strip().split("\n") if line.strip()]
        return subdomains

