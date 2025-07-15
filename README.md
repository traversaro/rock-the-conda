# rock-the-conda

Experiments related to conda-forge packaging of ROCM.

At the moment, it just contains some CMake/Python code to extract dependency info from TheRock, run:

~~~
pixi run download-therock
pixi run extract-deps
~~~

to generate a `the_rock_deps.png` file.
