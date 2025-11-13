"""
Dnsx wrapper for DNS resolution and validation.
"""

from .base_tool import BaseTool
from typing import List, Dict


class DnsxWrapper(BaseTool):
    """Wrapper for Dnsx DNS resolution tool."""
    
    def __init__(self):
        """Initialize Dnsx wrapper."""
        super().__init__("dnsx")
    
    def resolve_subdomains(self, subdomains: List[str]) -> List[Dict[str, str]]:
        """
        Resolve subdomains to IP addresses.
        
        Args:
            subdomains: List of subdomains to resolve
            
        Returns:
            List of dictionaries with subdomain and IP information
        """
        if not self.available or not subdomains:
            return []
        
        # Create temporary file with subdomains
        import tempfile
        with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.txt') as f:
            f.write('\n'.join(subdomains))
            temp_file = f.name
        
        try:
            # Execute: dnsx -l <subdomain_list> -a -aaaa -resp -silent
            # Use -resp to get IP addresses in output
            command = ["dnsx", "-l", temp_file, "-a", "-aaaa", "-resp", "-silent"]
            stdout, stderr, returncode = self.execute(command, timeout=300)
            
            if returncode != 0:
                return []
            
            # Parse output: Format is "subdomain [A] [ip1] [ip2]" or "subdomain [AAAA] [ipv6]"
            # ANSI color codes may be present, so we need to strip them
            import re
            results = []
            seen = set()  # Track seen subdomains to avoid duplicates
            subdomain_ips = {}  # Track IPs per subdomain
            
            for line in stdout.strip().split("\n"):
                line = line.strip()
                if not line:
                    continue
                
                # Skip banner/info lines
                if "dnsx" in line.lower() or "projectdiscovery" in line.lower() or "version" in line.lower() or line.startswith("_"):
                    continue
                
                # Remove ANSI color codes
                ansi_escape = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
                line = ansi_escape.sub('', line)
                
                # Parse: subdomain [A] [ip] or subdomain [AAAA] [ipv6]
                # Format: "subdomain [A] [104.18.36.214]" or "subdomain [AAAA] [ipv6]"
                parts = line.split()
                if len(parts) >= 3:
                    # Has format: subdomain [A/AAAA] [ip]
                    subdomain = parts[0]
                    ip = parts[2].strip('[]')  # IP is after [A] or [AAAA], remove brackets
                    
                    if subdomain not in subdomain_ips:
                        subdomain_ips[subdomain] = []
                    if ip not in subdomain_ips[subdomain]:
                        subdomain_ips[subdomain].append(ip)
                elif len(parts) >= 2:
                    # Might be: subdomain ip (without brackets)
                    subdomain = parts[0]
                    ip = parts[1].strip('[]')  # Remove brackets if present
                    if subdomain not in subdomain_ips:
                        subdomain_ips[subdomain] = []
                    if ip not in subdomain_ips[subdomain]:
                        subdomain_ips[subdomain].append(ip)
            
            # Build results from collected IPs
            for subdomain in subdomains:
                if subdomain in subdomain_ips and subdomain_ips[subdomain]:
                    results.append({
                        "subdomain": subdomain,
                        "ips": subdomain_ips[subdomain],
                        "resolved": True
                    })
                elif subdomain not in seen:
                    results.append({
                        "subdomain": subdomain,
                        "ips": [],
                        "resolved": False
                    })
                    seen.add(subdomain)
            
            return results
        finally:
            # Clean up temp file
            import os
            try:
                os.unlink(temp_file)
            except:
                pass

