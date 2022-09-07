struct Guest
    name::String
    gender::Symbol
end

function Base.show(io::IO, ::MIME"text/plain", g::Guest)
    println(io, typeof(g), ": ", g.name, " (", g.gender, ")")
    return nothing
end

struct Wish
    mail::String
    guest_ids::Vector{Int}
    gender::Symbol
end

function Base.show(io::IO, ::MIME"text/plain", w::Wish)
    println(io, length(w.guest_ids), "-person ", typeof(w), " from ", w.mail)
    return nothing
end

struct Room
    name::String
    capacity::Int
    gender::Symbol
end

function Base.show(io::IO, ::MIME"text/plain", r::Room)
    println(io, r.capacity, "-person ", typeof(r), " with name: ", r.name)
    return nothing
end

struct RoomAllocationProblem
    n_guests::Int
    n_wishes::Int
    n_rooms::Int
    n_beds::Int
    max_happiness::Int
    guests::Vector{Guest}
    wishes::Vector{Wish}
    rooms::Vector{Room}
    relations::SparseMatrixCSC{Int64, Int64}
    room_id_of_guest::Vector{Int}
    guest_ids_of_room::Vector{Vector{Int}}
    fulfilled_wishes::Vector{Bool}

    function RoomAllocationProblem(
        guests::Vector{Guest},
        wishes::Vector{Wish},
        rooms::Vector{Room}
    )
        n_guests = length(guests)
        n_wishes = length(wishes)
        n_rooms = length(rooms)
        n_beds = sum([r.capacity for r in rooms])
        if n_guests > n_beds
            msg = @sprintf(
                "Number of guests = %d; number of beds = %d\n Check the numbers!",
                n_guests,
                n_beds
            )
            error(msg)
        end
        relations = find_relations(wishes, n_beds)
        max_happiness = length(findall(!iszero, relations))
        room_id_of_guest = zeros(Int, n_guests)
        guest_ids_of_room = fill(Vector{Int}(), n_rooms)
        fulfilled_wishes = zeros(Bool, n_wishes)
        new(
            n_guests,
            n_wishes,
            n_rooms,
            n_beds,
            max_happiness,
            guests,
            wishes,
            rooms,
            relations,
            room_id_of_guest,
            guest_ids_of_room,
            fulfilled_wishes
        )
    end
end

function Base.show(io::IO, ::MIME"text/plain", rap::RoomAllocationProblem)
    println(io, rap.n_rooms, "-room ", typeof(r), ":")
    @printf(io, "  %d beds\n", rap.n_beds)
    @printf(io, "  %d guests\n", rap.n_guests)
    @printf(io, "  %d wishes\n", rap.n_wishes)
    return nothing
end

function Base.show(
    io::IO,
    ::MIME"text/plain",
    raps::Tuple{RoomAllocationProblem, RoomAllocationProblem}
)
    println(io, typeof(raps), ":")
    rap_1, rap_2 = raps
    println(io, "  ", rap_1.n_rooms, "-room ", typeof(rap_1), ":")
    @printf(io, "    %d beds\n", rap_1.n_beds)
    @printf(io, "    %d guests\n", rap_1.n_guests)
    @printf(io, "    %d wishes\n", rap_1.n_wishes)
    println(io, "  ", rap_2.n_rooms, "-room ", typeof(rap_2), ":")
    @printf(io, "    %d beds\n", rap_2.n_beds)
    @printf(io, "    %d guests\n", rap_2.n_guests)
    @printf(io, "    %d wishes\n", rap_2.n_wishes)
    return nothing
end

function RoomAllocationProblem(
    guests_file::String,
    wishes_file::String,
    rooms_file::String,
)
    guests = get_guests(guests_file)
    wishes = get_wishes(wishes_file, guests)
    rooms = get_rooms(rooms_file)
    return RoomAllocationProblem(guests, wishes, rooms)
end

function gender_separated_raps(
    guests_file::String,
    wishes_file::String,
    rooms_file::String
)
    guests = get_guests(guests_file)
    wishes = get_wishes(wishes_file, guests)
    rooms = get_rooms(rooms_file)
    guests_f, wishes_f = filter_genders(guests, wishes, :F)
    guests_m, wishes_m = filter_genders(guests, wishes, :M)
    rooms_f = filter(x -> x.gender == :F, rooms)
    rooms_m = filter(x -> x.gender == :M, rooms)
    rap_f = RoomAllocationProblem(guests_f, wishes_f, rooms_f)
    rap_m = RoomAllocationProblem(guests_m, wishes_m, rooms_m)
    return rap_f, rap_m
end

function get_guests(file::String)
    guests_raw, _ = readdlm(file, ';', String; header=true, skipblanks=true)
    guests = Vector{Guest}()
    for row in eachrow(guests_raw)
        name = strip(row[1])
        gender = Symbol(strip(row[2]))
        push!(guests, Guest(name, gender))
    end
    return guests
end

function get_wishes(file::String, guests::Vector{Guest})
    guest_names = [g.name for g in guests]
    unknown_guests = Dict{Int, Vector{String}}()
    wishes_raw = strip.(readdlm(file, ';', String; skipblanks=true))
    wishes = Vector{Wish}()

    for (wish_id, data) in enumerate(eachrow(wishes_raw))
        mail = data[1]
        names = data[2:end]
        guest_ids = Vector{Int}()
        unknown_guests_in_wish = Vector{String}()
        for name in names
            if !isempty(name)
                guest_id = findfirst(name .== guest_names)
                if isnothing(guest_id)
                    push!(unknown_guests_in_wish, name)
                else
                    push!(guest_ids, guest_id)
                end
            end
        end
        if !isempty(unknown_guests_in_wish)
            unknown_guests[wish_id] = unknown_guests_in_wish
        end
        guests_in_wish = guests[guest_ids]
        genders_equal = allequal([g.gender for g in guests_in_wish])
        if genders_equal
            gender = guests_in_wish[1].gender
        else
            gender = :MIX
        end
        wish = Wish(mail, guest_ids, gender)
        push!(wishes, wish)
    end

    if !isempty(unknown_guests)
        unknown_guests_info_file = joinpath(
            dirname(file),
            string("unknown_guests_in_",splitext(basename(file))[1],".txt")
        )
        open(unknown_guests_info_file, "w") do io
            write(io, "The following guests are unknown:\n")
            for (wish_id, names) in unknown_guests
                println(io)
                write(io, string("Wish of ", wishes[wish_id].mail), ":\n")
                for name in names
                    write(io, string("->", name, "<-\n"))
                end
            end
        end
        msg = @sprintf(
            "%d unknown guests found! Check the file '%s' for more details!",
            length(keys(unknown_guests)),
            basename(unknown_guests_info_file),
        )
        error(msg)
    end

    multiple_wishes = check_for_multiple_wishes(wishes, guests)
    if !isempty(multiple_wishes)
        multiple_wishes_info_file = joinpath(
            dirname(file),
            string("multiple_wishes_in_",splitext(basename(file))[1],".txt")
        )
        open(multiple_wishes_info_file, "w") do io
            write(io, "The following guests made multiple wishes:\n")
            for (guest_id, wishlist) in multiple_wishes
                println(io)
                write(io, guests[guest_id].name, ":\n")
                for wish_id in wishlist
                    write(io, string("Contained in wish of ", wishes[wish_id].mail), "\n")
                end
            end
        end
        msg = @sprintf(
            "%d multiple wishes found! Check the file '%s' for more details!",
            length(keys(multiple_wishes)),
            basename(multiple_wishes_info_file),
        )
        error(msg)
    end

    mixed_gender_wishes = [wish_id for wish_id in eachindex(wishes) if wishes[wish_id].gender == :MIX]
    if !isempty(mixed_gender_wishes)
        mixed_gender_wishes_info_file = joinpath(
            dirname(file),
            string("mixed_gender_wishes_in_",splitext(basename(file))[1],".txt")
        )
        open(mixed_gender_wishes_info_file, "w") do io
            write(io, "The following mixed gender wishes appear:\n")
            for wish_id in mixed_gender_wishes
                println(io)
                write(io, string("Wish of ", wishes[wish_id].mail), ":\n")
                for guest_id in wishes[wish_id].guest_ids
                    write(io, string(guests[guest_id].gender, ", ", guests[guest_id].name, "\n"))
                end
            end
        end
        msg = @sprintf(
            "%d mixed gender wishes found! Check the file '%s' for more details!",
            length(mixed_gender_wishes),
            basename(mixed_gender_wishes_info_file),
        )
        error(msg)
    end

    return wishes
end

function check_for_multiple_wishes(wishes::Vector{Wish}, guests::Vector{Guest})
    multiple_wishes = Dict{Int, Vector{Int}}()
    for guest_id in eachindex(guests)
        wishlist = Vector{Int}()
        for (wish_id, wish) in enumerate(wishes)
            if guest_id in wish.guest_ids
                push!(wishlist, wish_id)
            end
        end
        if length(wishlist) > 1
            multiple_wishes[guest_id] = wishlist
        end
    end
    return multiple_wishes
end

function get_rooms(file::String)
    rooms_raw, _ = readdlm(file, ';', String; header=true, skipblanks=true)
    rooms = Vector{Room}()
    for row in eachrow(rooms_raw)
        name = strip(row[1])
        capacity = parse(Int, row[2])
        gender = Symbol(strip(row[3]))
        push!(rooms, Room(name, capacity, gender))
    end
    return rooms
end

function find_relations(wishes::Vector{Wish}, n_beds::Int)
    relations = spzeros(Int, n_beds, n_beds)
    for wish in wishes
        for guest_id in wish.guest_ids
            friend_ids = wish.guest_ids[wish.guest_ids .!== guest_id]
            for friend_id in friend_ids
                relations[guest_id, friend_id] = -1
            end
        end
    end
    return relations
end

function filter_genders(guests::Vector{Guest}, wishes::Vector{Wish}, gender::Symbol)
    guests_gender = filter(x -> x.gender == gender, guests)
    wishes_gender = filter(x -> x.gender == gender, wishes)
    new_guest_ids = Dict{Int, Int}()
    for (new_id, guest) in enumerate(guests_gender)
        old_id = findfirst(x -> x == guest, guests)
        new_guest_ids[old_id] = new_id
    end
    for wish_id in eachindex(wishes_gender)
        old_ids = wishes_gender[wish_id].guest_ids
        for (i,old_id) in enumerate(old_ids)
            wishes_gender[wish_id].guest_ids[i] = new_guest_ids[old_id]
        end
    end
    return guests_gender, wishes_gender
end

function simulated_annealing!(rap::RoomAllocationProblem;
    start_temp=1.0,
    minimum_temp=1e-7,
    β=0.99,
    n_iter=100,
)
    printstyled(banner; color=:blue)
    if β >= 1
        error("Infinity-loop: β >= 1. Must be 0 < β < 1")
    end
    happiness_history = Vector{Float64}()
    target_happiness = -rap.max_happiness
    all_wishes_fulfilled = false
    current_allocation = initialize_allocation(rap)
    current_happiness = calc_happiness(current_allocation, rap.relations)
    temp_history = temperature_history(start_temp, minimum_temp, β)
    n_total_iter = length(temp_history) * n_iter
    happiness_history = zeros(Int, n_total_iter)
    iteration_counter = 0
    p = Progress(n_total_iter;
        dt=1,
        desc="Running...",
        barlen=50,
        color=:normal,
    )
    for temp in temp_history, _ in 1:n_iter
        iteration_counter += 1
        new_allocation = get_new_allocation(current_allocation, rap.n_rooms)
        new_happiness = calc_happiness(new_allocation, rap.relations)
        acceptance_probability = calc_acceptance_probability(
            current_happiness,
            new_happiness,
            temp
        )
        if acceptance_probability > rand()
            current_allocation = new_allocation
            current_happiness = new_happiness
        end
        happiness_history[iteration_counter] = current_happiness
        if current_happiness == target_happiness
            all_wishes_fulfilled = true
            happiness_history = happiness_history[1:iteration_counter]
            break
        end
        next!(p, showvalues=gen_showvals(iteration_counter, -current_happiness))
    end
    finish!(p)
    @printf("%.2f %% of wishes fulfilled\n", 100 * current_happiness/target_happiness)
    calc_room_id_of_guest!(rap, current_allocation)
    calc_guest_ids_of_room!(rap, current_allocation)
    calc_fulfilled_wishes!(rap)
    return happiness_history, temp_history
end

gen_showvals(iteration, happiness) = ()->[(:iteration, iteration), (:happiness, happiness)]

function temperature_history(temp, temp_min, β)
    temp_history = Vector{Float64}()
    while temp > temp_min
        push!(temp_history, temp)
        temp *= β
    end
    return temp_history
end

function initialize_allocation(rap::RoomAllocationProblem)
    allocation = spzeros(Int, rap.n_rooms, rap.n_beds)
    guest_ids = collect(1:rap.n_beds) # ghost-guests, so that n_guests == n_beds
    for (room_id, room) in enumerate(rap.rooms)
        capacity = room.capacity
        sample_guest_ids = sort(sample(guest_ids[guest_ids .> 0], capacity; replace=false))
        allocation[room_id, sample_guest_ids] .= 1
        guest_ids[sample_guest_ids] .= -1 # take guests out if assigned to a room
    end
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
    allocation_copy = copy(allocation)
    room_id_1, room_id_2 = sample(1:n_rooms, 2; replace=false)
    guest_id_1 = rand(findall(@views allocation_copy[room_id_1, :] .== 1))
    guest_id_2 = rand(findall(@views allocation_copy[room_id_2, :] .== 1))
    allocation_copy[room_id_1, guest_id_1] = 0 # switch rooms for two guests
    allocation_copy[room_id_1, guest_id_2] = 1
    allocation_copy[room_id_2, guest_id_2] = 0
    allocation_copy[room_id_2, guest_id_1] = 1
    dropzeros!(allocation_copy)
    return allocation_copy
end

function calc_room_id_of_guest!(
    rap::RoomAllocationProblem,
    allocation::SparseMatrixCSC{Int, Int},
)
    for (guest_id, col) in enumerate(eachcol(allocation[:, 1:rap.n_guests]))
        room_id = findfirst(col .> 0)
        if !isnothing(room_id)
            rap.room_id_of_guest[guest_id] = room_id
        end
    end
    return nothing
end

function calc_guest_ids_of_room!(
    rap::RoomAllocationProblem,
    allocation::SparseMatrixCSC{Int, Int},
)
    for (room_id, row) in enumerate(eachrow(allocation[:, 1:rap.n_guests]))
        guest_ids = findall(row .> 0)
        if !isnothing(guest_ids)
            rap.guest_ids_of_room[room_id] = guest_ids
        end
    end
    return nothing
end

function calc_fulfilled_wishes!(rap::RoomAllocationProblem)
    for (wish_id, wish) in enumerate(rap.wishes)
        guest_ids = wish.guest_ids
        wish_is_fulfilled = false
        friend_counter = 1
        room_id = rap.room_id_of_guest[guest_ids[1]]
        for friend_id in guest_ids[2:end]
            room_id_friend = rap.room_id_of_guest[friend_id]
            if room_id == room_id_friend
                friend_counter += 1
            end
        end
        if friend_counter == length(guest_ids)
            wish_is_fulfilled = true
        end
        rap.fulfilled_wishes[wish_id] = wish_is_fulfilled
    end
    return nothing
end

function export_wish_overview(file::String, rap::RoomAllocationProblem)
    open(file, "w") do io
        println(io, "="^92)
        println(io, "OVERVIEW OF ALL WISHES")
        println(io, "="^92)
        println(io)
        for (wish_id, wish) in enumerate(rap.wishes)
            wish_checkmark = rap.fulfilled_wishes[wish_id] ? "✔︎" : "✘"
            @printf(io, "%s %s (%s):\n", wish_checkmark, wish.mail, wish.gender)
            for guest_id in wish.guest_ids
                guest_name = rap.guests[guest_id].name
                guest_gender = rap.guests[guest_id].gender
                guest_room_name = rap.rooms[rap.room_id_of_guest[guest_id]].name
                @printf(io, "    %s (%s) - %s\n", guest_name, guest_gender, guest_room_name)
            end
            println(io)
        end
    end
    return nothing
end

function export_room_overview(file::String, rap::RoomAllocationProblem)
    open(file, "w") do io
        println(io, "="^92)
        println(io, "OVERVIEW OF ALL ROOMS")
        println(io, "="^92)
        println(io)
        for (room_id, room) in enumerate(rap.rooms)
            @printf(io, "%s (%s, %d beds):\n", room.name, room.gender, room.capacity)
            guest_ids = rap.guest_ids_of_room[room_id]
            for (bed_nr, guest_id) in enumerate(guest_ids)
                guest_name = rap.guests[guest_id].name
                guest_gender = rap.guests[guest_id].gender
                @printf(io, "    %d. %s (%s)\n", bed_nr, guest_name, guest_gender)
            end
            if length(guest_ids) < room.capacity
                for bed_nr in range(start=length(guest_ids)+1, stop=room.capacity)
                    @printf(io, "    %d. ---\n", bed_nr)
                end
            end
            println(io)
        end
    end
    return nothing
end

function export_guest_overview(file::String, rap::RoomAllocationProblem)
    open(file, "w") do io
        println(io, "name; gender; room")
        for (guest_id, guest) in enumerate(rap.guests)
            room_name = rap.rooms[rap.room_id_of_guest[guest_id]].name
            @printf(io, "%s; %s; %s\n", guest.name, guest.gender, room_name)
        end
    end
    return nothing
end

function export_results(rap::RoomAllocationProblem; dir::String="", prefix="")
    export_wish_overview(joinpath(dir, prefix, "wishes.txt"), rap)
    export_room_overview(joinpath(dir, prefix, "rooms.txt"), rap)
    export_guest_overview(joinpath(dir, prefix, "guests.csv"), rap)
    return nothing
end
