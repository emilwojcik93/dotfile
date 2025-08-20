#!/usr/bin/env python3
"""
Template for Python scripts with proper UTF-8 encoding and validation.

This template provides a starting point for Python scripts following
enterprise development standards with proper error handling, logging,
and documentation.

Author: Your Name
Date: 2025-08-03
Version: 1.0

Requirements:
    - Python 3.11 or later
    - UTF-8 encoding support

Change Log:
    1.0 - Initial version
"""

import argparse
import logging
import sys
import traceback
from pathlib import Path
from typing import Any, Dict, List, Optional, Union


# Configure logging
def setup_logging(log_level: str = "INFO", log_file: Optional[Path] = None) -> logging.Logger:
    """
    Set up logging configuration.

    Args:
        log_level: Logging level (DEBUG, INFO, WARNING, ERROR)
        log_file: Optional path to log file

    Returns:
        Configured logger instance
    """
    # Create logger
    logger = logging.getLogger(__name__)
    logger.setLevel(getattr(logging, log_level.upper()))

    # Create formatter
    formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )

    # Console handler
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)

    # File handler (if specified)
    if log_file:
        file_handler = logging.FileHandler(log_file, encoding='utf-8')
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)

    return logger


def validate_inputs(
    input_path: Path,
    output_path: Path,
    force: bool = False
) -> bool:
    """
    Validate input parameters.

    Args:
        input_path: Path to input file or directory
        output_path: Path where output will be saved
        force: Whether to overwrite existing files

    Returns:
        True if validation passes

    Raises:
        ValueError: If validation fails
    """
    # Check if input exists
    if not input_path.exists():
        raise ValueError(f"Input path does not exist: {input_path}")

    # Create output directory if needed
    output_path.parent.mkdir(parents=True, exist_ok=True)

    # Check if output exists and force is not specified
    if output_path.exists() and not force:
        raise ValueError(f"Output file exists and --force not specified: {output_path}")

    return True


def process_data(
    input_path: Path,
    output_path: Path,
    logger: logging.Logger
) -> Dict[str, Any]:
    """
    Main data processing function.

    Args:
        input_path: Path to input file or directory
        output_path: Path where output will be saved
        logger: Logger instance

    Returns:
        Dictionary with processing results

    Raises:
        Exception: If processing fails
    """
    try:
        logger.info(f"Starting processing of: {input_path}")

        # TODO: Implement your main logic here
        # Example: Read files, transform data, etc.

        if input_path.is_dir():
            logger.info(f"Processing directory with {len(list(input_path.iterdir()))} items")
            # Directory processing logic
            result = {"type": "directory", "items": len(list(input_path.iterdir()))}
        else:
            logger.info(f"Processing file of size {input_path.stat().st_size} bytes")
            # File processing logic
            result = {"type": "file", "size": input_path.stat().st_size}

        # Example output creation
        output_data = {
            "processed_at": str(Path(__file__).name),
            "input_path": str(input_path),
            "output_path": str(output_path),
            "status": "success",
            "details": result
        }

        # Save output with UTF-8 encoding
        import json
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(output_data, f, indent=2, ensure_ascii=False)

        logger.info(f"Output saved to: {output_path}")
        logger.info("Processing completed successfully")

        return output_data

    except Exception as e:
        logger.error(f"Error in processing: {str(e)}")
        logger.debug(traceback.format_exc())
        raise


def cleanup_resources(logger: logging.Logger) -> None:
    """
    Perform cleanup operations.

    Args:
        logger: Logger instance
    """
    logger.info("Performing cleanup operations...")

    # TODO: Add cleanup logic here
    # Example: Close connections, remove temporary files, etc.

    logger.info("Cleanup completed")


def main() -> int:
    """
    Main entry point.

    Returns:
        Exit code (0 for success, non-zero for failure)
    """
    # Set up argument parsing
    parser = argparse.ArgumentParser(
        description="Template Python script with proper encoding and validation",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    %(prog)s -i /path/to/input -o /path/to/output
    %(prog)s -i file.txt -o processed.json --force
    %(prog)s -i data/ -o results.json --log-level DEBUG
        """
    )

    parser.add_argument(
        '-i', '--input',
        type=Path,
        required=True,
        help='Path to input file or directory'
    )

    parser.add_argument(
        '-o', '--output',
        type=Path,
        required=True,
        help='Path where output will be saved'
    )

    parser.add_argument(
        '--force',
        action='store_true',
        help='Overwrite existing files without prompting'
    )

    parser.add_argument(
        '--log-level',
        choices=['DEBUG', 'INFO', 'WARNING', 'ERROR'],
        default='INFO',
        help='Set logging level (default: INFO)'
    )

    parser.add_argument(
        '--log-file',
        type=Path,
        help='Optional path to log file'
    )

    parser.add_argument(
        '--version',
        action='version',
        version='%(prog)s 1.0'
    )

    # Parse arguments
    args = parser.parse_args()

    # Set up logging
    logger = setup_logging(args.log_level, args.log_file)

    try:
        logger.info("=== Script Started ===")
        logger.info(f"Input: {args.input}")
        logger.info(f"Output: {args.output}")
        logger.info(f"Force: {args.force}")

        # Validate inputs
        validate_inputs(args.input, args.output, args.force)
        logger.info("Input validation completed successfully")

        # Process data
        result = process_data(args.input, args.output, logger)

        logger.info("=== Script Completed Successfully ===")
        return 0

    except KeyboardInterrupt:
        logger.warning("Script interrupted by user")
        return 130

    except Exception as e:
        logger.error("=== Script Failed ===")
        logger.error(f"Error: {str(e)}")
        logger.debug(traceback.format_exc())
        return 1

    finally:
        cleanup_resources(logger)


if __name__ == "__main__":
    # Set UTF-8 encoding for output
    import os
    os.environ['PYTHONIOENCODING'] = 'utf-8'

    # Run main function
    exit_code = main()
    sys.exit(exit_code)
