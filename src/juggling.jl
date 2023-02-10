
"""
    juggle!(rjj::RoomJugglerJob; config=JuggleConfig())

Function to start juggling of the guests in the `RoomJugglerJob`.

# Arguments
- `rjj::RoomJugglerJob`: `RoomJugglerJob` that gets juggled
- `config`: two possible options:
    - `config::JuggleConfig`: same configuration for the female and male problem
    - `config::Tuple{JuggleConfig, JuggleConfig}`: two configurations, the first is for the
      female problem, the second is for the male problem
"""
function juggle!(rjj::RoomJugglerJob; config=JuggleConfig())
    log_init()
    if typeof(config) == JuggleConfig
        printstyled("\nFEMALES:\n"; color=:blue, bold=true, underline=true)
        juggle_rop!(rjj.ropf, config)
        printstyled("\nMALES:\n"; color=:blue, bold=true, underline=true)
        juggle_rop!(rjj.ropm, config)
    elseif typeof(config) == Tuple{JuggleConfig, JuggleConfig}
        printstyled("\nFEMALES:\n"; color=:blue, bold=true, underline=true)
        config_f = config[1]
        juggle_rop!(rjj.ropf, config_f)
        printstyled("\nMALES:\n"; color=:blue, bold=true, underline=true)
        config_m = config[2]
        juggle_rop!(rjj.ropm, config_m)
    else
        error("Keyword config must be of type JuggleConfig or Tuple{JuggleConfig, " *
            "JuggleConfig}!")
    end
    return nothing
end

function juggle_rop!(rop::RoomOccupancyProblem, config::JuggleConfig)
    # skip if problem already solved and skip juggling if true
    if problem_solved(rop)
        println("All wishes already fulfilled, skipping juggling.")
        return nothing
    end

    # initial random room allocation
    current_allocation = initialize_allocation(rop)

    # calc happiness for this initial room allocation
    current_happiness = calc_happiness(current_allocation, rop.relations)

    # initializations
    target_happiness = -rop.max_happiness
    all_wishes_fulfilled = false
    iteration_counter = 0
    p = Progress(config.n_total_iter;
        dt=1,
        desc="juggling guests...",
        barlen=28,
        color=:normal,
    )

    log_start(config, -target_happiness)

    # juggling-loop
    elapsed_time = @elapsed begin
        for temp in config.t_history, _ in 1:config.n_iter
            iteration_counter += 1

            # get random new allocation
            new_allocation = get_new_allocation(current_allocation, rop.n_rooms)

            # calc the new happiness for this allocation
            new_happiness = calc_happiness(new_allocation, rop.relations)

            # calc the probability of accepting the new allocation
            acceptance_probability = calc_acceptance_probability(
                current_happiness,
                new_happiness,
                temp
            )

            # accept if probability is higher than random value
            if acceptance_probability > rand()
                current_allocation = new_allocation
                current_happiness = new_happiness
            end

            # break if all wishes are fulfilled
            if current_happiness == target_happiness
                all_wishes_fulfilled = true
                break
            end

            # update ProgressMeter
            next!(p, showvalues=gen_showvals(iteration_counter, -current_happiness))
        end
    end
    finish!(p)

    @printf("✔︎ simulated annealing completed after %g seconds\n", elapsed_time)

    # updates
    calc_room_id_of_guest!(rop, current_allocation)
    calc_guest_ids_of_room!(rop, current_allocation)
    calc_fulfilled_wishes!(rop)

    log_results(rop, current_happiness, iteration_counter)

    return nothing
end

function problem_solved(rop::RoomOccupancyProblem)
    n_unfulfilled_wishes = length(findall(rop.fulfilled_wishes .== false))
    if n_unfulfilled_wishes > 0
        return false
    else
        return true
    end
end

gen_showvals(iteration, happiness) = ()->[(:iteration, iteration), (:happiness, happiness)]

function temperature_history(t_0, t_min, β)
    t_history = Vector{Float64}()
    t = copy(t_0)
    while t > t_min
        push!(t_history, t)
        t *= β
    end
    return t_history
end

function initialize_allocation(rap::RoomOccupancyProblem)
    # initialize sparse matrix
    allocation = spzeros(Int, rap.n_rooms, rap.n_beds)

    # initialize guests
    # add ghost-guests, so that n_guests == n_beds
    guest_ids = collect(1:rap.n_beds)

    # loop over all rooms and assign the beds
    for (room_id, room) in enumerate(rap.rooms)
        capacity = room.capacity
        sample_guest_ids = sort(sample(guest_ids[guest_ids .> 0], capacity; replace=false))
        allocation[room_id, sample_guest_ids] .= 1
        guest_ids[sample_guest_ids] .= -1 # take guests out if assigned to a room
    end

    # check if the capacity of the room is exceeded
    used_capacity = sum(allocation; dims=2)
    for (room_id, room) in enumerate(rap.rooms)
        @assert room.capacity == used_capacity[room_id]
    end

    return allocation
end

calc_happiness(allocation, relations) = tr(allocation * relations * allocation')

function calc_acceptance_probability(current_happiness, new_happiness, temp)
    if new_happiness < current_happiness
        return 1
    else
        return exp((current_happiness - new_happiness) / temp)
    end
end

function get_new_allocation(allocation, n_rooms)
    # copy so that the current one is not modified
    allocation_copy = copy(allocation)

    # randomly choose two rooms
    room_id_1, room_id_2 = sample(1:n_rooms, 2; replace=false)

    # randomly choose two guests
    guest_id_1 = rand(findall(@views allocation_copy[room_id_1, :] .== 1))
    guest_id_2 = rand(findall(@views allocation_copy[room_id_2, :] .== 1))

    # switch rooms of these two guests
    allocation_copy[room_id_1, guest_id_1] = 0
    allocation_copy[room_id_1, guest_id_2] = 1
    allocation_copy[room_id_2, guest_id_2] = 0
    allocation_copy[room_id_2, guest_id_1] = 1

    # maintaining sparsity
    dropzeros!(allocation_copy)

    return allocation_copy
end

function calc_room_id_of_guest!(
    rap::RoomOccupancyProblem,
    allocation::SparseMatrixCSC{Int, Int},
)
    # loop over all guests
    for (guest_id, col) in enumerate(eachcol(allocation[:, 1:rap.n_guests]))
        room_id = findfirst(col .> 0)
        # every guest needs a room, error if room_id === nothing
        rap.room_id_of_guest[guest_id] = room_id
    end

    return nothing
end

function calc_guest_ids_of_room!(
    rap::RoomOccupancyProblem,
    allocation::SparseMatrixCSC{Int, Int},
)
    # loop over all rooms
    for (room_id, row) in enumerate(eachrow(allocation[:, 1:rap.n_guests]))
        guest_ids = findall(row .> 0)
        if !isnothing(guest_ids) # ignore unused rooms
            rap.guest_ids_of_room[room_id] = guest_ids
        end
    end

    return nothing
end

function calc_fulfilled_wishes!(rap::RoomOccupancyProblem)
    # loop over all wishes
    for (wish_id, wish) in enumerate(rap.wishes)

        # initializations
        guest_ids = wish.guest_ids
        wish_is_fulfilled = false
        friend_counter = 1
        room_id = rap.room_id_of_guest[guest_ids[1]]

        # count the friends in the same room as friend 1
        for friend_id in guest_ids[2:end]
            room_id_friend = rap.room_id_of_guest[friend_id]
            if room_id == room_id_friend
                friend_counter += 1
            end
        end

        # if all friends are in the room, the wish is fulfilled
        if friend_counter == length(guest_ids)
            wish_is_fulfilled = true
        end
        rap.fulfilled_wishes[wish_id] = wish_is_fulfilled
    end

    return nothing
end
