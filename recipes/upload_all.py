#!/usr/bin/env python3
"""
Upload all conda packages from output/linux-64/ directory to prefix.dev
"""

import subprocess
import sys
from pathlib import Path


def main():
    # Define the output directory
    output_dir = Path("./output/linux-64")
    
    # Check if directory exists
    if not output_dir.exists():
        print(f"Error: Directory {output_dir} does not exist")
        sys.exit(1)
    
    # Find all .conda files
    conda_packages = list(output_dir.glob("*.conda"))
    
    if not conda_packages:
        print(f"No .conda packages found in {output_dir}")
        sys.exit(0)
    
    print(f"Found {len(conda_packages)} packages to upload")
    
    # Upload URL
    upload_url = "https://prefix.dev/api/v1/upload/rock-the-conda"
    
    # Upload each package
    failed_uploads = []
    for i, package in enumerate(conda_packages, 1):
        print(f"\n[{i}/{len(conda_packages)}] Uploading {package.name}...")
        
        try:
            result = subprocess.run(
                ["pixi", "upload", upload_url, str(package)],
                check=True,
                capture_output=True,
                text=True
            )
            print(f"✓ Successfully uploaded {package.name}")
            if result.stdout:
                print(result.stdout)
        except subprocess.CalledProcessError as e:
            print(f"✗ Failed to upload {package.name}")
            print(f"Error: {e.stderr}")
            failed_uploads.append(package.name)
        except FileNotFoundError:
            print("Error: 'pixi' command not found. Please ensure pixi is installed and in PATH")
            sys.exit(1)
    
    # Summary
    print("\n" + "="*60)
    print(f"Upload complete: {len(conda_packages) - len(failed_uploads)}/{len(conda_packages)} successful")
    
    if failed_uploads:
        print(f"\nFailed uploads ({len(failed_uploads)}):")
        for pkg in failed_uploads:
            print(f"  - {pkg}")
        sys.exit(1)
    else:
        print("All packages uploaded successfully!")
        sys.exit(0)


if __name__ == "__main__":
    main()
