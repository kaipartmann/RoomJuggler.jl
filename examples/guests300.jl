using HappyScheduler

guests = joinpath(@__DIR__, "guests300.csv")
wishes = joinpath(@__DIR__, "wishes300.csv")
rooms = joinpath(@__DIR__, "rooms300.csv")

gwrf, gwrm = get_gwr_split_genders(guests, wishes, rooms)

rapf = RoomAllocationProblem(gwrf...)
simulated_annealing!(rapf; start_temp=1, minimum_temp=1e-7, β=0.999, n_iter=300)
export_results(rapf; dir=@__DIR__, prefix="results_f_")

rapm = RoomAllocationProblem(gwrm...)
simulated_annealing!(rapm; start_temp=1, minimum_temp=1e-7, β=0.999, n_iter=300)
export_results(rapm; dir=@__DIR__, prefix="results_m_")
