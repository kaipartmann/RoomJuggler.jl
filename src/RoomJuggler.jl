module RoomJuggler

using Printf
using SparseArrays
using LinearAlgebra
using StatsBase: sample
using ProgressMeter
using XLSX
using Logging

export Guest, Wish, Room, RoomJugglerJob, JuggleConfig
export juggle!
export report

include("types.jl")
include("data_import.jl")
include("juggling.jl")
include("io.jl")
include("utility.jl")

end
