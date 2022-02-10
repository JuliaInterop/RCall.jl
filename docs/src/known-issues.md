## Installing packages via Conda

When using the Conda environment, installing packages via `install.packages` or `devtools` will result in installation failures such as "x86_64-conda-linux-gnu-cc: not found".
Instead, use Conda to install packages.
For example, `Conda.add("r-ggplot2")`.
