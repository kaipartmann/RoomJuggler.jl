using RoomJuggler

guests = joinpath(@__DIR__, "guests1000.csv")
wishes = joinpath(@__DIR__, "wishes1000.csv")
rooms = joinpath(@__DIR__, "rooms1040.csv")
gwrf, gwrm = get_gwr_split_genders(guests, wishes, rooms)

xfile = joinpath(@__DIR__, "TemplateRoomJuggler.xlsx")
gwrf, gwrm = get_gwr_split_genders(xfile)

rapf = RoomAllocationProblem(gwrf...)
simulated_annealing!(rapf; start_temp=1, minimum_temp=1e-7, β=0.999, n_iter=300)
export_results(rapf; dir=@__DIR__, prefix="female_")

rapm = RoomAllocationProblem(gwrm...)
simulated_annealing!(rapm; start_temp=1, minimum_temp=1e-7, β=0.999, n_iter=300)
export_results(rapm; dir=@__DIR__, prefix="male_")
