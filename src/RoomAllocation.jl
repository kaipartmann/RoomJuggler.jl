module RoomAllocation

struct Guest
    id::Int
    name::String
end

mutable struct Wish
    const ids::Vector{Int}
    const names::Vector{String}
    fulfilled::Bool
end

mutable struct Room
    const id::Int
    const name::String
    const capacity::Int
    allocation::Vector{Int}
end

struct RoomAllocationProblem
    Guests::Vector{Guest}
    Wishes::Vector{Wish}
    Rooms::Vector{Room}
end

function simulated_annealing(rap::RoomAllocationProblem;
    temp=1.0,
    temp_min=1e-7,
    β=0.99,
    n_iter=100
)
    return nothing
end

end
