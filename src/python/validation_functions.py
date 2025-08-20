#!/usr/bin/env python3
"""
Python Script Validation Module
Infrastructure as Code validation functions for Python scripts

Author: Emil Wójcik
Version: 1.0.0
Compatible: Python 3.7+
"""

import os
import sys
import logging
import platform
import subprocess
import socket
import shutil
from pathlib import Path
from typing import Union, List, Optional, Tuple
import time
import signal


class ScriptValidator:
    """Comprehensive validation class for Python scripts following IaC principles"""
    
    def __init__(self, script_name: str = None, log_level: int = logging.INFO):
        self.script_name = script_name or Path(sys.argv[0]).name
        self.script_version = "1.0.0"
        self.logger = self._setup_logging(log_level)
        self.validation_errors = 0
        
    def _setup_logging(self, level: int) -> logging.Logger:
        """Set up logging with proper formatting"""
        logger = logging.getLogger(self.script_name)
        logger.setLevel(level)
        
        if not logger.handlers:
            handler = logging.StreamHandler(sys.stdout)
            formatter = logging.Formatter(
                '%(asctime)s - %(levelname)s - %(message)s',
                datefmt='%Y-%m-%d %H:%M:%S'
            )
            handler.setFormatter(formatter)
            logger.addHandler(handler)
            
        return logger
    
    def validate_python_version(self, min_version: Tuple[int, int] = (3, 7)) -> bool:
        """Validate Python version meets minimum requirements"""
        current = sys.version_info[:2]
        if current >= min_version:
            self.logger.info(f"Python version validation passed: {'.'.join(map(str, current))}")
            return True
        else:
            self.logger.error(f"Python version {'.'.join(map(str, current))} is below minimum required {'.'.join(map(str, min_version))}")
            self.validation_errors += 1
            return False
    
    def validate_command(self, command: str, alternatives: List[str] = None) -> bool:
        """Test if a command/tool is available in the system"""
        alternatives = alternatives or []
        
        # Test primary command
        if shutil.which(command):
            self.logger.info(f"Command validation passed: {command}")
            return True
            
        # Test alternatives
        for alt_cmd in alternatives:
            if shutil.which(alt_cmd):
                self.logger.info(f"Command validation passed: {alt_cmd} (alternative for {command})")
                return True
        
        self.logger.error(f"Required command not found: {command}")
        self.validation_errors += 1
        return False
    
    def validate_path(self, path: Union[str, Path], path_type: str = "any", 
                     check_writable: bool = False) -> bool:
        """Advanced path validation with type checking and permissions"""
        path_obj = Path(path)
        
        # Basic existence check
        if not path_obj.exists():
            self.logger.error(f"Path does not exist: {path}")
            self.validation_errors += 1
            return False
        
        # Type-specific validation
        if path_type == "file" and not path_obj.is_file():
            self.logger.error(f"Path is not a file: {path}")
            self.validation_errors += 1
            return False
        elif path_type == "directory" and not path_obj.is_dir():
            self.logger.error(f"Path is not a directory: {path}")
            self.validation_errors += 1
            return False
        
        # Write access check
        if check_writable:
            try:
                if path_obj.is_dir():
                    test_file = path_obj / f"test_write_{int(time.time())}.tmp"
                    test_file.touch()
                    test_file.unlink()
                else:
                    # For files, check if parent directory is writable
                    parent_test = path_obj.parent / f"test_write_{int(time.time())}.tmp"
                    parent_test.touch()
                    parent_test.unlink()
                    
                self.logger.info(f"Write access validated: {path}")
            except (OSError, PermissionError) as e:
                self.logger.error(f"Path {path} is not writable: {e}")
                self.validation_errors += 1
                return False
        
        self.logger.info(f"Path validation passed: {path}")
        return True
    
    def validate_network(self, host: str = "github.com", port: int = 443, 
                        timeout: int = 5) -> bool:
        """Test network connectivity"""
        try:
            socket.create_connection((host, port), timeout=timeout).close()
            self.logger.info(f"Network connectivity validated: {host}:{port}")
            return True
        except (socket.error, socket.timeout) as e:
            self.logger.warning(f"Network connectivity test failed for {host}:{port} - {e}")
            return False
    
    def validate_imports(self, modules: List[str]) -> bool:
        """Validate that required Python modules can be imported"""
        missing_modules = []
        
        for module in modules:
            try:
                __import__(module)
                self.logger.info(f"Module import validation passed: {module}")
            except ImportError:
                self.logger.error(f"Required module not available: {module}")
                missing_modules.append(module)
                self.validation_errors += 1
        
        if missing_modules:
            self.logger.error(f"Missing required modules: {', '.join(missing_modules)}")
            return False
        
        return True
    
    def validate_os(self, supported_os: List[str] = None) -> bool:
        """Validate operating system"""
        supported_os = supported_os or ["Windows", "Linux", "Darwin"]
        current_os = platform.system()
        
        if current_os in supported_os:
            self.logger.info(f"Operating system validation passed: {current_os}")
            return True
        else:
            self.logger.error(f"Unsupported OS. Required: {supported_os}, Found: {current_os}")
            self.validation_errors += 1
            return False
    
    def validate_disk_space(self, path: Union[str, Path], min_gb: float = 1.0) -> bool:
        """Validate available disk space"""
        try:
            statvfs = os.statvfs(str(path))
            available_gb = (statvfs.f_frsize * statvfs.f_bavail) / (1024**3)
            
            if available_gb >= min_gb:
                self.logger.info(f"Disk space validation passed: {available_gb:.2f}GB available")
                return True
            else:
                self.logger.error(f"Insufficient disk space. Required: {min_gb}GB, Available: {available_gb:.2f}GB")
                self.validation_errors += 1
                return False
        except (OSError, AttributeError):
            # Fallback for Windows or other systems
            self.logger.warning("Unable to check disk space on this system")
            return True
    
    def get_system_info(self) -> dict:
        """Get comprehensive system information"""
        return {
            "python_version": f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}",
            "platform": platform.platform(),
            "architecture": platform.architecture()[0],
            "processor": platform.processor() or "Unknown",
            "hostname": platform.node(),
            "user": os.getenv("USER", os.getenv("USERNAME", "Unknown")),
            "script_path": Path(sys.argv[0]).resolve(),
            "working_directory": Path.cwd(),
            "python_executable": sys.executable
        }
    
    def validate_system(self, 
                       min_python_version: Tuple[int, int] = (3, 7),
                       required_commands: List[str] = None,
                       required_modules: List[str] = None,
                       supported_os: List[str] = None) -> bool:
        """Comprehensive system validation"""
        self.logger.info("Starting comprehensive system validation...")
        
        # Log system information
        sys_info = self.get_system_info()
        self.logger.info(f"System Information:")
        for key, value in sys_info.items():
            self.logger.info(f"  {key}: {value}")
        
        # Validate Python version
        self.validate_python_version(min_python_version)
        
        # Validate operating system
        if supported_os:
            self.validate_os(supported_os)
        
        # Validate required commands
        if required_commands:
            for cmd in required_commands:
                self.validate_command(cmd)
        
        # Validate required modules
        if required_modules:
            self.validate_imports(required_modules)
        
        # Validate basic paths
        self.validate_path(Path.cwd(), "directory", check_writable=True)
        
        # Network validation (optional)
        if not self.validate_network():
            self.logger.warning("Network validation failed, continuing anyway")
        
        # Disk space validation
        self.validate_disk_space(Path.cwd(), min_gb=0.1)
        
        if self.validation_errors > 0:
            self.logger.error(f"System validation failed with {self.validation_errors} errors")
            return False
        else:
            self.logger.info("System validation completed successfully")
            return True
    
    def prompt_with_timeout(self, prompt: str, timeout: int = 10, 
                           default: str = "") -> str:
        """Prompt user with automatic timeout for automation compatibility"""
        def timeout_handler(signum, frame):
            raise TimeoutError("Prompt timeout")
        
        print(f"{prompt} (auto-continues in {timeout}s): ", end="", flush=True)
        
        try:
            # Set up signal handler for timeout (Unix only)
            if hasattr(signal, 'SIGALRM'):
                signal.signal(signal.SIGALRM, timeout_handler)
                signal.alarm(timeout)
            
            response = input()
            
            if hasattr(signal, 'SIGALRM'):
                signal.alarm(0)  # Cancel alarm
            
            return response
        except (TimeoutError, KeyboardInterrupt):
            print()
            self.logger.warning(f"No input detected, using default: {default}")
            return default


def main():
    """Example usage of the validation system"""
    validator = ScriptValidator("example-script")
    
    # Basic validation
    if not validator.validate_system(
        min_python_version=(3, 7),
        required_commands=["git", "python"],
        required_modules=["os", "sys", "pathlib"],
        supported_os=["Windows", "Linux", "Darwin"]
    ):
        print("System validation failed!")
        sys.exit(1)
    
    # Example prompt with timeout
    response = validator.prompt_with_timeout("Continue? (y/N)", 10, "n")
    
    if response.lower() != 'y':
        print("Operation cancelled")
        sys.exit(0)
    
    print("Validation passed! Script can continue...")


if __name__ == "__main__":
    main()
