#!/usr/bin/env python3
"""
Build conda-forge feedstocks using rattler-build.

This script iterates through all downloaded feedstocks and builds them
using rattler-build.
"""

import os
import subprocess
import sys
import yaml
from pathlib import Path


def load_workspace_config(ws_file="feedstocks.yaml"):
    """Load the workspace configuration file."""
    with open(ws_file, 'r') as f:
        return yaml.safe_load(f)


def build_feedstock(feedstock_path):
    """Build a single feedstock using rattler-build."""
    recipe_path = feedstock_path / "recipe"
    
    if not recipe_path.exists():
        print(f"Warning: No recipe directory found in {feedstock_path}")
        return False
    
    # Look for meta.yaml or recipe.yaml
    meta_yaml = recipe_path / "meta.yaml"
    recipe_yaml = recipe_path / "recipe.yaml"
    
    recipe_file = None
    if meta_yaml.exists():
        recipe_file = meta_yaml
    elif recipe_yaml.exists():
        recipe_file = recipe_yaml
    else:
        print(f"Warning: No meta.yaml or recipe.yaml found in {recipe_path}")
        return False
    
    print(f"Building {feedstock_path.name} using {recipe_file.name}...")
    
    try:
        # Run rattler-build
        cmd = [
            "rattler-build",
            "build",
            "--recipe", str(recipe_file),
            "--output-dir", "conda-bld"
        ]
        
        result = subprocess.run(
            cmd,
            cwd=feedstock_path.parent,
            capture_output=True,
            text=True
        )
        
        if result.returncode == 0:
            print(f"✓ Successfully built {feedstock_path.name}")
            return True
        else:
            print(f"✗ Failed to build {feedstock_path.name}")
            print(f"Error: {result.stderr}")
            return False
            
    except Exception as e:
        print(f"✗ Exception while building {feedstock_path.name}: {e}")
        return False


def main():
    """Main function to build all feedstocks."""
    # Load workspace configuration
    try:
        config = load_workspace_config()
    except FileNotFoundError:
        print("Error: conda_superbuild/ws.yaml not found")
        sys.exit(1)
    except yaml.YAMLError as e:
        print(f"Error parsing conda_superbuild/ws.yaml: {e}")
        sys.exit(1)
    
    feedstocks_dir = Path("feedstocks")
    
    if not feedstocks_dir.exists():
        print("Error: feedstocks directory not found. Run 'pixi run download-feedstocks' first.")
        sys.exit(1)
    
    # Create output directory for built packages
    conda_bld_dir = Path("conda-bld")
    conda_bld_dir.mkdir(exist_ok=True)
    
    repositories = config.get("repositories", {})
    if not repositories:
        print("No repositories found in workspace configuration")
        return
    
    success_count = 0
    total_count = len(repositories)
    
    print(f"Found {total_count} feedstocks to build...")
    print("-" * 50)
    
    # Build each feedstock
    for repo_name, repo_config in repositories.items():
        feedstock_path = feedstocks_dir / repo_name
        
        if not feedstock_path.exists():
            print(f"Warning: {feedstock_path} not found, skipping...")
            continue
        
        if build_feedstock(feedstock_path):
            success_count += 1
    
    print("-" * 50)
    print(f"Build summary: {success_count}/{total_count} feedstocks built successfully")
    
    if success_count < total_count:
        print(f"Note: {total_count - success_count} feedstocks failed to build")
        sys.exit(1)


if __name__ == "__main__":
    main()
