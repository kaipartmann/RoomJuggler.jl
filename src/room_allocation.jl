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

struct RoomAllocationProblem
    n_guests::Int
    n_wishes::Int
    n_rooms::Int
    n_beds::Int
    guests::Vector{Guest}
    wishes::Vector{Wish}
    rooms::Vector{Room}
    relations::SparseMatrixCSC{Int64, Int64}
end

function RoomAllocationProblem(guests::Vector{Guest}, wishes::Vector{Wish}, rooms::Vector{Room})
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
    rap = RoomAllocationProblem(
        n_guests,
        n_wishes,
        n_rooms,
        n_beds,
        guests,
        wishes,
        rooms,
        relations,
    )
    return rap
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
        guest_ids = Vector{Int}()
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

function initialize_allocation(rap::RoomAllocationProblem)
    allocation = spzeros(Int, rap.n_rooms, rap.n_beds)
    guest_ids = collect(1:rap.n_beds) # ghost-guests, so that n_guests == n_beds
    for (room_id, room) in enumerate(rap.rooms)
        capacity = room.capacity
        sample_guest_ids = sort(sample(guest_ids[guest_ids .> 0], capacity; replace=false))
        allocation[room_id, sample_guest_ids] .= 1
        guest_ids[sample_guest_ids] .= -1 # take guests out if assigned to a room
    end
    return allocation
end

function simulated_annealing(rap::RoomAllocationProblem;
    start_temp=1.0,
    minimum_temp=1e-7,
    β=0.99,
    n_iter=100
)
    if β >= 1
        error("Infinity-loop: β >= 1. Must be 0 < β < 1")
    end
    guests_per_wish = [length(w.guest_ids) for w in rap.wishes]
    target_happiness = -sum(guests_per_wish .* guests_per_wish .-1)
    all_wishes_fulfilled = false
    current_allocation = initialize_allocation(rap)
    current_happiness = calc_happiness(current_allocation, rap.relations)
    temp = start_temp
    while temp < minimum_temp
        for _ in 1:n_iter
            new_allocation = get_new_allocation(current_allocation, rap.n_rooms)
            new_happiness = calc_happiness(new_allocation, rap.relations)
            acceptance_probability = calc_accept_prob(current_happiness, new_happiness, temp)
            if acceptance_probability > rand()
                current_allocation = new_allocation
                current_happiness = new_happiness
            end
            if current_happiness == target_happiness
                all_wishes_fulfilled = true
                break
            end
        end
        temp *= β
    end
    room_id_of_guest = zeros(Int, rap.n_guests)
    for (guest_id, col) in enumerate(eachcol(current_allocation[:, 1:rap.n_guests]))
        room_ids = findall(col .> 1)
        if !isnothing(room_ids) && length(room_ids) == 1
            room_id_of_guest[guest_id] = room_ids[1]
        end
    end
    return room_id_of_guest, current_allocation
end

calc_happiness(a, r) = tr(a * r * a')

calc_accept_prob(ch, nh, t) = nh < ch ? 1 : exp((ch - nh) / t)

function get_new_allocation(allocation, n_rooms)
    allocation_copy = copy(allocation)
    room_id_1, room_id_2 = sample(1:n_rooms, 2; replace=false)
    guest_id_1 = rand(findall(@views allocation_copy[room_id_1, :] .== 1))
    guest_id_2 = rand(findall(@views allocation_copy[room_id_2, :] .== 1))
    # switch rooms for two guests
    allocation_copy[room_id_1, guest_id_1] = 0
    allocation_copy[room_id_1, guest_id_2] = 1
    allocation_copy[room_id_2, guest_id_2] = 0
    allocation_copy[room_id_2, guest_id_1] = 1
    dropzeros!(allocation_copy)
end
