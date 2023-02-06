using RoomJuggler

guests = joinpath(@__DIR__, "guests300.csv")
wishes = joinpath(@__DIR__, "wishes300.csv")
rooms = joinpath(@__DIR__, "rooms300.csv")

rjj = RoomJugglerJob(guests, wishes, rooms)
juggle!(rjj)

export_results(joinpath(@__DIR__, "results"), rjj)
