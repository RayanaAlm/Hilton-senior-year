"""
Base class for all tool wrappers.
"""

import subprocess
import shutil
from typing import List, Dict, Optional


class BaseTool:
    """Base class for OSINT tool wrappers."""
    
    def __init__(self, tool_name: str):
        """
        Initialize the base tool.
        
        Args:
            tool_name: Name of the tool command
        """
        self.tool_name = tool_name
        self.available = self.check_availability()
    
    def check_availability(self) -> bool:
        """
        Check if the tool is installed and available in PATH.
        
        Returns:
            True if tool is available, False otherwise
        """
        return shutil.which(self.tool_name) is not None
    
    def execute(self, command: List[str], timeout: Optional[int] = None) -> tuple[str, str, int]:
        """
        Execute a command and return stdout, stderr, and return code.
        
        Args:
            command: Command to execute as list
            timeout: Optional timeout in seconds
            
        Returns:
            Tuple of (stdout, stderr, return_code)
        """
        try:
            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                timeout=timeout
            )
            return result.stdout, result.stderr, result.returncode
        except subprocess.TimeoutExpired:
            return "", "Command timed out", 1
        except Exception as e:
            return "", str(e), 1
    
    def parse_output(self, output: str) -> Dict:
        """
        Parse tool output. Override in subclasses.
        
        Args:
            output: Raw output from tool
            
        Returns:
            Parsed output as dictionary
        """
        return {"raw": output}

