using HappyScheduler
using Documenter

DocMeta.setdocmeta!(HappyScheduler, :DocTestSetup, :(using HappyScheduler); recursive=true)

makedocs(;
    modules=[HappyScheduler],
    authors="Kai Friebertshäuser",
    repo="https://github.com/kfrb/HappyScheduler.jl/blob/{commit}{path}#{line}",
    sitename="HappyScheduler.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://kfrb.github.io/HappyScheduler.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/kfrb/HappyScheduler.jl",
    devbranch="main",
)
