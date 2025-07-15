#!/usr/bin/env python3
"""

import argparset.py
----------------------------

Create a dependency graph of sub‑projects declared in AMD ROCm *TheRock*.

Features
~~~~~~~~
* Uses CMake to properly extract `therock_cmake_subproject_declare()` calls with variable expansion.
* Collects BUILD_DEPS and RUNTIME_DEPS by overriding the CMake function.
* Filters external dependencies (starting with 'therock-') by default for cleaner graphs.
* Groups projects by GitHub repository using colored background boxes.
* External dependencies are grouped in a gray "External Dependencies" box.
* Generates a NetworkX DiGraph with root dependencies at top, leaves at bottom.
* Writes a Graphviz .dot file with repository-based subgraphs.
* Renders a PNG/SVG with Graphviz's `dot` (hierarchical layout).

Usage
~~~~~
Run with pixi to ensure all dependencies are available:
    pixi run extract-deps                    # Exclude external deps (recommended)
    pixi run extract-deps-with-external      # Include external deps

Or directly with Python (requires manual dependency installation):
    python3 extract_the_rock_deps.py TheRock                    # Exclude external deps
    python3 extract_the_rock_deps.py TheRock --include-external # Include external deps
    python3 extract_the_rock_deps.py TheRock --project-info custom_prj_info.yaml  # Custom project info

Requires:  Python 3.8+, networkx, pydot (optional but recommended), PyYAML,
           CMake, and Graphviz binaries (`dot`) on your PATH for rendering.
"""

import argparse
import re
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Tuple, Optional

import networkx as nx
from networkx.drawing.nx_pydot import write_dot
import yaml


# ---------------------------------------------------------------------------
# 1.  CMake-based dependency extraction
# ---------------------------------------------------------------------------

def load_project_repo_info(yaml_path: Path) -> Dict[str, str]:
    """
    Load project to GitHub repository mapping from YAML file.
    
    Args:
        yaml_path: Path to the YAML file containing project repository mappings
        
    Returns:
        Dictionary mapping project names to their GitHub repository URLs
    """
    project_repo_map = {}
    
    if not yaml_path.exists():
        print(f"Warning: Project info file {yaml_path} not found. Repository grouping will be disabled.")
        return project_repo_map
    
    try:
        with open(yaml_path, 'r') as f:
            data = yaml.safe_load(f)
            
        for project_name, project_info in data.items():
            if isinstance(project_info, dict) and 'github_repo' in project_info:
                github_repo = project_info['github_repo']
                if isinstance(github_repo, list):
                    # For projects with multiple repos, use the first one as primary
                    project_repo_map[project_name] = github_repo[0]
                else:
                    project_repo_map[project_name] = github_repo
                    
    except Exception as e:
        print(f"Warning: Error loading project info from {yaml_path}: {e}")
        
    print(f"Loaded repository information for {len(project_repo_map)} projects")
    return project_repo_map


def extract_deps_with_cmake(source_dir: Path) -> List[Tuple[str, List[str]]]:
    """
    Use CMake to extract dependencies by overriding therock_cmake_subproject_declare.
    This approach handles variable expansion and catches all declarations.
    """
    # Create a temporary build directory
    build_dir = Path(__file__).parent / "build_extract_deps"
    project_dir = Path(__file__).parent / "extract_deps_project"
    deps_file = build_dir / "therock_deps.txt"
    
    # Clean up any existing build directory
    if build_dir.exists():
        import shutil
        shutil.rmtree(build_dir)
    
    build_dir.mkdir(exist_ok=True)
    
    print(f"Running CMake extraction from {source_dir}...")
    print(f"Using build directory: {build_dir}")
    
    try:
        # Configure the CMake project
        result = subprocess.run(
            [
                "cmake", 
                f"-DTHEROCK_SOURCE_DIR={source_dir.absolute()}",
                "-DTHEROCK_AMDGPU_FAMILIES=gfx1100",
                str(project_dir)
            ],
            cwd=build_dir,
            check=True,
            capture_output=True,
            text=True
        )
        
        print("CMake configuration completed successfully")
        if result.stdout:
            print("CMake output:")
            print(result.stdout)
            
    except subprocess.CalledProcessError as e:
        print(f"CMake configuration failed: {e}")
        print(f"stdout: {e.stdout}")
        print(f"stderr: {e.stderr}")
        return []
    except FileNotFoundError:
        print("Error: CMake not found on PATH")
        return []
    
    # Parse the output file
    if not deps_file.exists():
        print("Error: Dependencies file was not created")
        return []
    
    results = []
    try:
        with open(deps_file, 'r') as f:
            for line in f:
                line = line.strip()
                if not line or ':' not in line:
                    continue
                
                project_name, deps_str = line.split(':', 1)
                deps = [d.strip() for d in deps_str.split(',') if d.strip()]
                results.append((project_name, deps))
                
    except Exception as e:
        print(f"Error parsing dependencies file: {e}")
        return []
    
    print(f"Extracted {len(results)} projects with dependencies")
    return results


# ---------------------------------------------------------------------------
# 2.  Graph construction & DOT rendering
# ---------------------------------------------------------------------------

def should_exclude_external_node(node_name: str, include_external: bool) -> bool:
    """
    Check if a node should be excluded based on external dependency filtering.
    
    Args:
        node_name: The name of the node/dependency
        include_external: Whether to include external dependencies
        
    Returns:
        True if the node should be excluded, False otherwise
    """
    return not include_external and node_name.startswith('therock-')


def build_graph(pairs: List[Tuple[str, List[str]]], include_external: bool = False, 
                project_repo_map: Optional[Dict[str, str]] = None) -> nx.DiGraph:
    g = nx.DiGraph()
    
    if project_repo_map is None:
        project_repo_map = {}
    
    # First pass: add main project nodes (filter external projects too)
    for node, deps in pairs:
        # Skip external projects (starting with 'therock-') unless explicitly included
        if should_exclude_external_node(node, include_external):
            continue
        
        # Determine the repository for this node
        repo = project_repo_map.get(node, "unknown")
        if node.startswith('therock-'):
            repo = "external"
        
        g.add_node(node, repository=repo)
    
    # Second pass: add edges and dependency nodes
    for node, deps in pairs:
        # Skip external projects (starting with 'therock-') unless explicitly included
        if should_exclude_external_node(node, include_external):
            continue
            
        for d in deps:
            # Skip external dependencies (starting with 'therock-') unless explicitly included
            if should_exclude_external_node(d, include_external):
                continue
            
            # Add the dependency node if it doesn't exist yet
            if not g.has_node(d):
                # Determine the repository for this dependency
                repo = project_repo_map.get(d, "unknown")
                if d.startswith('therock-'):
                    repo = "external"
                g.add_node(d, repository=repo)
            
            # Reverse the edge direction: dependency -> dependent
            # This makes dependencies appear at the top, dependents at the bottom
            g.add_edge(d, node)
    return g


def create_colored_dot_with_subgraphs(g: nx.DiGraph, dot_path: Path) -> None:
    """
    Create a DOT file with repository-based subgraphs and colored backgrounds.
    """
    # Group nodes by repository
    repo_nodes = {}
    for node in g.nodes():
        repo = g.nodes[node].get('repository', 'unknown')
        if repo not in repo_nodes:
            repo_nodes[repo] = []
        repo_nodes[repo].append(node)
    
    # Define colors for different repositories
    repo_colors = {
        'external': '#CCCCCC',  # Gray for external dependencies
        'ROCm/rocm-cmake': '#FFE6E6',      # Light red
        'ROCm/rocm-core': '#E6F3FF',       # Light blue
        'ROCm/HIP': '#E6FFE6',             # Light green
        'ROCm/clr': '#E6FFE6',             # Light green (same as HIP since they're related)
        'ROCm/rocm_smi_lib': '#FFF0E6',    # Light orange
        'ROCm/rocprofiler-register': '#F0E6FF',  # Light purple
        'ROCm/half': '#E6FFFF',            # Light cyan
        'ROCm/llvm-project': '#FFFFE6',    # Light yellow
        'ROCm/HIPIFY': '#FFE6F0',          # Light pink
        'ROCm/ROCR-Runtime': '#F0FFE6',    # Light lime
        'ROCm/rocminfo': '#E6F0FF',        # Light sky blue
        'ROCm/rocprof-trace-decoder': '#FFE6CC', # Light peach
        'ROCm/aqlprofile': '#E6CCFF',      # Light lavender
        'ROCm/rocprofiler-sdk': '#CCFFE6', # Light mint
        'ROCm/roctracer': '#FFCCCC',       # Light salmon
        'ROCm/rccl': '#CCFFFF',            # Light aqua
        'ROCm/rocm-libraries': '#F5F5DC',  # Beige for the large math/ML libraries group
        'unknown': '#F0F0F0',              # Light gray for unknown repos
    }
    
    lines = ['digraph G {']
    lines.append('\trankdir=TB;')
    lines.append('\tcompound=true;')
    lines.append('\tnewrank=true;')
    lines.append('')
    
    # Create subgraphs for each repository
    cluster_id = 0
    for repo, nodes in repo_nodes.items():
        if not nodes:
            continue
            
        color = repo_colors.get(repo, '#F0F0F0')
        
        # Create cluster name
        if repo == 'external':
            cluster_name = 'External Dependencies'
        elif repo == 'unknown':
            cluster_name = 'Unknown Repository'
        else:
            cluster_name = repo
            
        lines.append(f'\tsubgraph cluster_{cluster_id} {{')
        lines.append(f'\t\tlabel="{cluster_name}";')
        lines.append(f'\t\tstyle=filled;')
        lines.append(f'\t\tfillcolor="{color}";')
        lines.append(f'\t\tcolor=black;')
        lines.append('')
        
        # Add nodes to this subgraph
        for node in nodes:
            lines.append(f'\t\t"{node}";')
        
        lines.append('\t}')
        lines.append('')
        cluster_id += 1
    
    # Add edges
    lines.append('\t// Edges')
    for edge in g.edges():
        lines.append(f'\t"{edge[0]}" -> "{edge[1]}";')
    
    lines.append('}')
    
    with open(dot_path, 'w') as f:
        f.write('\n'.join(lines))


def render_with_dot(
    g: nx.DiGraph,
    dot_path: Path,
    png_path: Path | None = None,
    svg_path: Path | None = None,
) -> None:
    # Create the DOT file with repository-based subgraphs
    create_colored_dot_with_subgraphs(g, dot_path)
    
    for out, flag in ((png_path, "-Tpng"), (svg_path, "-Tsvg")):
        if out is None:
            continue
        try:
            subprocess.run(
                ["dot", flag, dot_path, "-o", out],
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            print(f"✔ wrote {out}")
        except FileNotFoundError:
            print("⚠ Graphviz 'dot' not found on PATH – cannot render.", file=sys.stderr)
            return
        except subprocess.CalledProcessError as e:
            print(f"⚠ dot failed: {e.stderr.decode()}", file=sys.stderr)
            return


# ---------------------------------------------------------------------------
# 3.  Main
# ---------------------------------------------------------------------------

def main() -> None:
    ap = argparse.ArgumentParser(
        description="Extract TheRock dependency graph and render with Graphviz dot."
    )
    ap.add_argument("source_dir", type=Path, help="Path to TheRock source tree")
    ap.add_argument("--dot", type=Path, default=Path("the_rock_deps.dot"), help="DOT output path")
    ap.add_argument("--png", type=Path, default=Path("the_rock_deps.png"), help="PNG output path")
    ap.add_argument("--svg", type=Path, help="SVG output path (optional)")
    ap.add_argument("--include-external", action="store_true", 
                    help="Include external dependencies (starting with 'therock-') in the graph")
    ap.add_argument("--project-info", type=Path, default=Path("prj_info.yaml"),
                    help="Path to YAML file containing project repository mappings")
    args = ap.parse_args()

    # Load project repository mappings
    project_repo_map = load_project_repo_info(args.project_info)

    pairs = extract_deps_with_cmake(args.source_dir)
    
    # Filter and report on external dependencies
    total_deps = sum(len(deps) for _, deps in pairs)
    external_deps = sum(1 for _, deps in pairs for d in deps if d.startswith('therock-'))
    
    if external_deps > 0:
        if args.include_external:
            print(f"Including {external_deps} external dependencies (therock-*) in the graph")
        else:
            print(f"Excluding {external_deps} external dependencies (therock-*) from the graph")
            print("Use --include-external to include them")
    
    g = build_graph(pairs, args.include_external, project_repo_map)

    render_with_dot(g, args.dot, args.png, args.svg)

    # Create a colored DOT file with subgraphs for each repository
    create_colored_dot_with_subgraphs(g, Path("the_rock_deps_colored.dot"))


if __name__ == "__main__":
    main()

