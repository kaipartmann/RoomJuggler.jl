
function get_guests(file::String)
    # check correct file extension
    !endswith(file, ".csv") && error("$file not a .csv file")

    # read raw guests from csv file
    guests_raw = CSV.File(file; types=Dict(:name => String, :gender => Symbol), strict=true)

    # convert raw guests to Vector{Guest}
    guests = Vector{Guest}()
    for row in guests_raw
        push!(guests, Guest(row.name, row.gender))
    end

    # check for duplicates
    length(guests) > length(unique(guests)) && error("guest duplicates found")

    return guests
end

function get_wishes(file::String, guests::Vector{Guest})
    # check correct file extension
    !endswith(file, ".csv") && error("$file not a .csv file")

    # read raw wishes from csv file
    wishes_raw = CSV.File(file;
        header=false,
        delim=';',
        types=String,
        stripwhitespace=true,
        silencewarnings=true,
    )
    if length(first(wishes_raw)) < 2
        error("found only 1 column in $file, \nneed ';' as delimiter!")
    end

    # initializations
    unknown_guest_errorflag = false
    mixed_gender_wish_errorflag = false
    guest_names = [g.name for g in guests]
    wishes = Vector{Wish}()

    # loop over all raw wishes
    for row in wishes_raw

        # get e-mail from raw wish
        mail = first(row)
        !contains(mail, "@") && error("$mail is not a valid e-mail adress")

        # get names of the wish friends
        names = Vector{String}()
        for i in firstindex(row)+1:lastindex(row)
            !ismissing(row[i]) && push!(names, row[i])
        end
        isempty(names) && error("no names in wish with mail: $mail")

        # find corresponding guest_ids of the wish friends
        guest_ids = Vector{Int}()
        for name in names
            guest_id = findfirst(name .== guest_names)
            if isnothing(guest_id)
                unknown_guest_errorflag = true
                @error "unknown guest in wish:" mail name
            else
                push!(guest_ids, guest_id)
            end
        end

        # check for same gender
        guests_in_wish = guests[guest_ids]
        genders_equal = allequal([g.gender for g in guests_in_wish])
        if genders_equal
            gender = guests_in_wish[begin].gender
        else
            mixed_gender_wish_errorflag = true
            @error "mixed gender wish found:" guests_in_wish
            gender = :mixed
        end

        # create Wish instance
        wish = Wish(mail, guest_ids, gender)
        push!(wishes, wish)
    end

    # thow errors
    unknown_guest_errorflag && error("unkown guests found")
    mixed_gender_wish_errorflag && error("mixed gender wishes found")

    check_for_multiple_wishes(wishes, guests)

    return wishes
end

function check_for_multiple_wishes(wishes::Vector{Wish}, guests::Vector{Guest})
    multiple_wishes_errorflag = false

    # check for each guest
    for guest_id in eachindex(guests)

        # create a wishlist with all wish_ids of this guest
        wishlist = Vector{Int}()
        for (wish_id, wish) in enumerate(wishes)
            if guest_id in wish.guest_ids
                push!(wishlist, wish_id)
            end
        end

        # error if guest is found in more than one wish
        if length(wishlist) > 1
            multiple_wishes_errorflag = true
            name = guests[guest_id].name
            wish_mails = [w.mail for w in wishes[wishlist]]
            @error "multiple wishes specified!" name wish_mails
        end
    end

    # throw error
    multiple_wishes_errorflag && error("guest(s) with multiple wishes found")

    return nothing
end

function get_rooms(file::String)
    # check correct file extension
    !endswith(file, ".csv") && error("$file not a .csv file")

    # read raw rooms from csv file
    rooms_raw = CSV.File(file;
        types=Dict(:name => String, :capacity => Int, :gender => Symbol),
        stripwhitespace=true,
    )

    # convert raw rooms to Vector{Room}
    rooms = [Room(r[1], r[2], r[3]) for r in rooms_raw]

    return rooms
end

function find_relations(wishes::Vector{Wish}, n_beds::Int)
    # initialization
    relations = spzeros(Int, n_beds, n_beds)

    # loop over all wishes
    for wish in wishes
        for guest_id in wish.guest_ids
            # find the wish friends for each guest
            friend_ids = wish.guest_ids[wish.guest_ids .!== guest_id]

            # relation between friends is -1, otherwise 0
            for friend_id in friend_ids
                relations[guest_id, friend_id] = -1
            end
        end
    end

    return relations
end

function filter_genders(guests::Vector{Guest}, wishes::Vector{Wish}, gender::Symbol)
    # get all guests and wishes with the specified gender
    guests_gender = filter(x -> x.gender == gender, guests)
    wishes_gender = filter(x -> x.gender == gender, wishes)

    # create a Dict mapping old_id => new_id
    new_guest_ids = Dict{Int, Int}()
    for (new_id, guest) in enumerate(guests_gender)
        old_id = findfirst(x -> x == guest, guests)
        new_guest_ids[old_id] = new_id
    end

    # change the old guest_ids to the new guest_ids in wishes_gender
    for wish_id in eachindex(wishes_gender)
        old_ids = wishes_gender[wish_id].guest_ids
        for (i,old_id) in enumerate(old_ids)
            wishes_gender[wish_id].guest_ids[i] = new_guest_ids[old_id]
        end
    end

    return guests_gender, wishes_gender
end
