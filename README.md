# ExpectationMaximizationPCA.jl
ExpectationMaximizationPCA.jl (EMPCA) is a Julia rewrite of [empca](https://github.com/sbailey/empca) which provides weighted Expectation Maximization PCA, an iterative method for solving PCA while properly weighting data.

## Installation

The most current, tagged version of [ExpectationMaximizationPCA.jl](https://github.com/christiangil/ExpectationMaximizationPCA.jl) can be easily installed using Julia's Pkg

```julia
Pkg.add("ExpectationMaximizationPCA")
```

If you would like to contribute to the package, or just want to run the latest (untagged) version, you can use the following

```julia
Pkg.develop("ExpectationMaximizationPCA")
```

## Example

```julia
import ExpectationMaximizationPCA as EMPCA

## making data
nx = 200  # dimensionality of observations
nt = 50  # number of observations
σ = ((((((1:nx) .- nx/2).^2) ./ (nx/2)^2) .+ 1)* ones(nt)') ./ 3 # noise, edges are twice as noisy as the center
data = rand(nt)' .* sin.(((1:nx) ./ nx) * 2π) + (0.2 .* rand(nt)') .* cos.(((1:nx) ./ nx) * 2π)  # a mixture of sin and cos signals
data .+= σ .* randn(size(data))  # add Gaussian noise

## performing EMPCA
nb = 2  # number of basis vectors
μ = vec(mean(data; dims=2))  # mean observation
weights = 1 ./ σ.^2  # use inverse variance as the weights
# weights = ones(size(data))  # uniform weights replicates PCA
basis_vecs, scores = EMPCA.EMPCA(μ, nb, data, weights)  # perform EMPCA  on `data` .- `μ` with `nb` basis vectors using `weights` for weighting
```

## Documentation
The documentation for this package is available [here](https://christiangil.github.io/ExpectationMaximizationPCA.jl/).

The original python version can be found [here](https://github.com/sbailey/empca).

## Citation
The paper S. Bailey 2012, PASP, 124, 1015 describes the underlying math
and is available as a pre-print at:
http://arxiv.org/abs/1208.4122

If you use this code in an academic paper, please include a citation
as described in CITATION.txt, and optionally an acknowledgement such as:

> This work uses the Weighted EMPCA code by Stephen Bailey,
> available at https://github.com/sbailey/empca/
