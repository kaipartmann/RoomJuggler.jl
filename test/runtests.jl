using HappyScheduler
using Test
using SafeTestsets

@testset "HappyScheduler.jl" begin
    @safetestset "RoomAllocation" begin include(joinpath("room_allocation", "test_room_allocation.jl")) end
end
