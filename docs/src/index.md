```@meta
CurrentModule = ExpectationMaximizationPCA
```

# ExpectationMaximizationPCA.jl Documentation

ExpectationMaximizationPCA.jl is a Julia rewrite of [empca](https://github.com/sbailey/empca) which provides Weighted Expectation Maximization PCA, an iterative method for solving PCA while properly weighting data.


## Primary function definitions
The [`ExpectationMaximizationPCA.EMPCA`](@ref) function is the primary function provided by ExpectationMaximizationPCA.jl

```@docs
ExpectationMaximizationPCA.EMPCA
```

```@docs
ExpectationMaximizationPCA.EMPCA!
```

## Citing EMPCA

If you use `ExpectationMaximizationPCA.jl` in an academic paper, please include a citation to
S. Bailey 2012, PASP, 124, 1015.

BibTeX entry:
```
@ARTICLE{2012PASP..124.1015B,
   author = {{Bailey}, S.},
    title = "{Principal Component Analysis with Noisy and/or Missing Data}",
  journal = {\pasp},
archivePrefix = "arXiv",
   eprint = {1208.4122},
 primaryClass = "astro-ph.IM",
 keywords = {Data Analysis and Techniques},
     year = 2012,
    month = sep,
   volume = 124,
    pages = {1015-1023},
      doi = {10.1086/668105},
   adsurl = {http://adsabs.harvard.edu/abs/2012PASP..124.1015B},
  adsnote = {Provided by the SAO/NASA Astrophysics Data System}
}
```


## Indices

All of the package functions can be found here

```@contents
Pages = ["indices.md"]
```
