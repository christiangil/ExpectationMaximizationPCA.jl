# push!(LOAD_PATH,"../src/")
using Documenter
import ExpectationMaximizationPCA

# DocMeta.setdocmeta!(ExpectationMaximizationPCA, :DocTestSetup, :(using ExpectationMaximizationPCA); recursive=true)

makedocs(
    sitename = "ExpectationMaximizationPCA.jl",
    format = Documenter.HTML(),
    modules = [ExpectationMaximizationPCA],
    authors = "Christian Gilbertson",
    pages = [
        "Home" => "index.md",
        hide("Indices" => "indices.md"),
        "LICENSE.md",
    ]
)

deploydocs(
    repo = "github.com/christiangil/ExpectationMaximizationPCA.jl.git",
    deploy_config = Documenter.GitHubActions(),
)