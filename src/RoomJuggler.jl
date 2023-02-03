module RoomJuggler

using DelimitedFiles
using Printf
using SparseArrays
using LinearAlgebra
using StatsBase: sample
using ProgressMeter
using XLSX

export Guest, Wish, Room, RoomAllocationProblem, get_gwr_split_genders, get_gwr
export simulated_annealing!
export export_results

const BANNER = raw"""
░▒█▀▀▄░▄▀▀▄░▄▀▀▄░█▀▄▀█░░░░▒█░█░▒█░█▀▀▀░█▀▀▀░█░░█▀▀░█▀▀▄
░▒█▄▄▀░█░░█░█░░█░█░▀░█░░░░▒█░█░▒█░█░▀▄░█░▀▄░█░░█▀▀░█▄▄▀
░▒█░▒█░░▀▀░░░▀▀░░▀░░▒▀░▒█▄▄█░░▀▀▀░▀▀▀▀░▀▀▀▀░▀▀░▀▀▀░▀░▀▀

"""

include("room_allocation.jl")

end
