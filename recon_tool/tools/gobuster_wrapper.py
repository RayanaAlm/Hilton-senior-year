"""
Gobuster wrapper for directory/file brute-forcing.
"""

from .base_tool import BaseTool
from typing import List, Dict
import os


class GobusterWrapper(BaseTool):
    """Wrapper for Gobuster directory brute-forcing tool."""
    
    def __init__(self):
        """Initialize Gobuster wrapper."""
        super().__init__("gobuster")
        self.default_wordlist = self._create_minimal_wordlist()
    
    def _create_minimal_wordlist(self) -> str:
        """Create a minimal wordlist for POC."""
        # Minimal wordlist for proof of concept
        words = [
            "admin", "api", "assets", "backup", "blog", "cdn", "dev", "docs",
            "download", "files", "images", "img", "js", "login", "mail", "old",
            "php", "private", "public", "secure", "static", "test", "tmp", "www"
        ]
        
        # Create temp wordlist file
        import tempfile
        temp_file = tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.txt')
        temp_file.write('\n'.join(words))
        temp_file.close()
        return temp_file.name
    
    def discover_directories(self, url: str, wordlist: str = None) -> List[Dict[str, str]]:
        """
        Discover directories/files on a target URL.
        
        Args:
            url: Target URL (e.g., http://example.com)
            wordlist: Optional custom wordlist path
            
        Returns:
            List of discovered paths
        """
        if not self.available:
            return []
        
        wordlist_path = wordlist or self.default_wordlist
        
        if not os.path.exists(wordlist_path):
            return []
        
        # Execute: gobuster dir -u <url> -w <wordlist> -q
        command = ["gobuster", "dir", "-u", url, "-w", wordlist_path, "-q"]
        stdout, stderr, returncode = self.execute(command, timeout=300)
        
        if returncode != 0:
            return []
        
        # Parse output: discovered paths
        results = []
        for line in stdout.strip().split("\n"):
            if not line.strip() or "Starting gobuster" in line or "Finished" in line:
                continue
            
            # Parse gobuster output format
            # Format: /path (Status: 200) [Size: 1234]
            if "(" in line and "Status:" in line:
                path = line.split()[0] if line.split() else ""
                status = ""
                if "Status:" in line:
                    status_part = line.split("Status:")[1].split(")")[0].strip()
                    status = status_part
                
                results.append({
                    "path": path,
                    "status": status,
                    "url": url
                })
        
        return results
    
    def __del__(self):
        """Clean up temporary wordlist file."""
        try:
            if hasattr(self, 'default_wordlist') and os.path.exists(self.default_wordlist):
                os.unlink(self.default_wordlist)
        except:
            pass

