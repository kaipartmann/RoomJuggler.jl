using RoomJuggler
using Documenter

DocMeta.setdocmeta!(RoomJuggler, :DocTestSetup, :(using RoomJuggler); recursive=true)

makedocs(;
    modules=[RoomJuggler],
    authors="Kai Friebertshäuser",
    repo="https://github.com/kfrb/RoomJuggler.jl/blob/{commit}{path}#{line}",
    sitename="RoomJuggler.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://kfrb.github.io/RoomJuggler.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "step_by_step.md",
        "API" => "api.md",
    ],
)

deploydocs(;
    repo="github.com/kfrb/RoomJuggler.jl",
    devbranch="main",
)
