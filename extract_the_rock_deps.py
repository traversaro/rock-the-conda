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
* Generates a NetworkX DiGraph with root dependencies at top, leaves at bottom.
* Writes a Graphviz .dot file.
* Renders a PNG/SVG with Graphviz's `dot` (hierarchical layout).

Usage
~~~~~
Run with pixi to ensure all dependencies are available:
    pixi run extract-deps                    # Exclude external deps (recommended)
    pixi run extract-deps-with-external      # Include external deps

Or directly with Python (requires manual dependency installation):
    python3 extract_the_rock_deps.py TheRock                    # Exclude external deps
    python3 extract_the_rock_deps.py TheRock --include-external # Include external deps

Requires:  Python 3.8+, networkx, pydot (optional but recommended),
           CMake, and Graphviz binaries (`dot`) on your PATH for rendering.
"""

import argparse
import re
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Tuple

import networkx as nx
from networkx.drawing.nx_pydot import write_dot


# ---------------------------------------------------------------------------
# 1.  CMake-based dependency extraction
# ---------------------------------------------------------------------------

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

def build_graph(pairs: List[Tuple[str, List[str]]], include_external: bool = False) -> nx.DiGraph:
    g = nx.DiGraph()
    
    # First pass: add main project nodes (filter external projects too)
    for node, deps in pairs:
        # Skip external projects (starting with 'therock-') unless explicitly included
        if not include_external and node.startswith('therock-'):
            continue
        g.add_node(node)
    
    # Second pass: add edges and dependency nodes
    for node, deps in pairs:
        # Skip external projects (starting with 'therock-') unless explicitly included
        if not include_external and node.startswith('therock-'):
            continue
            
        for d in deps:
            # Skip external dependencies (starting with 'therock-') unless explicitly included
            if not include_external and d.startswith('therock-'):
                continue
            
            # Add the dependency node if it doesn't exist yet
            if not g.has_node(d):
                g.add_node(d)
            
            # Reverse the edge direction: dependency -> dependent
            # This makes dependencies appear at the top, dependents at the bottom
            g.add_edge(d, node)
    return g


def render_with_dot(
    g: nx.DiGraph,
    dot_path: Path,
    png_path: Path | None = None,
    svg_path: Path | None = None,
) -> None:
    # Write the DOT file with top-to-bottom ranking
    write_dot(g, dot_path)
    
    # Read the DOT file and add graph attributes for better layout
    dot_content = dot_path.read_text()
    # Add rankdir=TB for top-to-bottom layout right after the digraph declaration
    if 'digraph' in dot_content and 'rankdir' not in dot_content:
        lines = dot_content.split('\n')
        for i, line in enumerate(lines):
            if line.strip().startswith('digraph'):
                lines.insert(i + 1, '\trankdir=TB;')
                break
        dot_path.write_text('\n'.join(lines))
    
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
    args = ap.parse_args()

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
    
    g = build_graph(pairs, args.include_external)

    render_with_dot(g, args.dot, args.png, args.svg)


if __name__ == "__main__":
    main()

