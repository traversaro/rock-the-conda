# rock-the-conda

Experiments related to conda-forge packaging of ROCm.

This repository is just a container of experiments, it is not in any way a container of useful way of using ROCm in conda-forge.

If you are interested in ROCm support in conda-forge, please monitor official issues in conda-forge organizations like:
* https://github.com/conda-forge/conda-forge.github.io/issues/1923
* https://github.com/conda-forge/staged-recipes/issues/10123

## Features

### TheRock Dependency Analysis

One functionality of this repo is some tooling to extract dependencies information of rocm packages from [`TheRock`](https://github.com/ROCm/TheRock):

~~~bash
pixi run download-therock
pixi run extract-deps
~~~

This generates a `the_rock_deps.png` file showing the dependency graph, see https://github.com/conda-forge/conda-forge.github.io/issues/1923#issuecomment-3074199892 for an example of such image.

### Build TheRock with conda-forge compilers

[`TheRock`](https://github.com/ROCm/TheRock) is a cmake-based superbuild/virtual monorepo infrastructure to build all the ROCm packages, including their dependencies. To compile it with conda-forge dependencies, run:

~~~
pixi run download-therock-all
pixi run build-therock
~~~

### Conda-forge Feedstock Building

As a playground for official conda-forge PRs, this repo contains a way to build conda-forge feedstocks for ROCm packages:

~~~bash
pixi run build-feedstocks
~~~


The feedstocks to build are configured in `feedstocks.yaml` and build in order the following feedstocks:
- `rocm-cmake`
- `rocm-devices-libs`
- `rocm-comgr`
- `rocr-runtime`
- `rocminfo`
- `hip`
- `rocm-smi`

Built packages will be placed in the `conda-bld/` directory.
