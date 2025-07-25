#!/usr/bin/env python3
"""
Utility script to validate and show information about the conda-forge feedstocks workspace.
"""

import yaml
import sys
from pathlib import Path


def validate_workspace_config(ws_file="feedstocks.yaml"):
    """Validate the workspace configuration file."""
    try:
        with open(ws_file, 'r') as f:
            config = yaml.safe_load(f)
    except FileNotFoundError:
        print(f"Error: {ws_file} not found")
        return None
    except yaml.YAMLError as e:
        print(f"Error parsing {ws_file}: {e}")
        return None
    
    return config


def show_workspace_info(config):
    """Display information about the workspace."""
    repositories = config.get("repositories", {})
    
    print(f"Conda-forge feedstocks workspace configuration")
    print("=" * 50)
    print(f"Number of repositories: {len(repositories)}")
    print()
    
    print("Repositories:")
    print("-" * 30)
    for name, repo_config in repositories.items():
        repo_type = repo_config.get("type", "unknown")
        url = repo_config.get("url", "no url")
        version = repo_config.get("version", "no version")
        print(f"  {name}")
        print(f"    Type: {repo_type}")
        print(f"    URL: {url}")
        print(f"    Version: {version}")
        print()


def check_feedstocks_status():
    """Check the status of downloaded feedstocks."""
    feedstocks_dir = Path("feedstocks")
    
    if not feedstocks_dir.exists():
        print("Feedstocks directory not found. Run 'pixi run download-feedstocks' to download.")
        return
    
    print("Downloaded feedstocks:")
    print("-" * 30)
    
    for item in feedstocks_dir.iterdir():
        if item.is_dir():
            recipe_dir = item / "recipe"
            has_recipe = recipe_dir.exists()
            
            meta_yaml = recipe_dir / "meta.yaml" if has_recipe else None
            recipe_yaml = recipe_dir / "recipe.yaml" if has_recipe else None
            
            recipe_file = None
            if meta_yaml and meta_yaml.exists():
                recipe_file = "meta.yaml"
            elif recipe_yaml and recipe_yaml.exists():
                recipe_file = "recipe.yaml"
            
            status = "✓" if recipe_file else "✗"
            recipe_info = f" ({recipe_file})" if recipe_file else " (no recipe found)"
            
            print(f"  {status} {item.name}{recipe_info}")


def main():
    """Main function."""
    if len(sys.argv) > 1 and sys.argv[1] == "status":
        check_feedstocks_status()
        return
    
    config = validate_workspace_config()
    if config is None:
        sys.exit(1)
    
    show_workspace_info(config)


if __name__ == "__main__":
    main()
