
function get_raw_data(file::String)
    # check correct file extension
    !endswith(file, ".xlsx") && error("$file not a .xlsx file")

    # read excel file
    xf = XLSX.readxlsx(file)

    # check the sheets in the excel file
    sheets = XLSX.sheetnames(xf)
    guest_sheet = findall(sheets .== "guests")
    isnothing(guest_sheet) && error("File must contain one sheet with name `guests`!")
    length(guest_sheet) > 1 && error("File contains multiple sheets with name `guests`!")
    wishes_sheet = findall(sheets .== "wishes")
    isnothing(wishes_sheet) && error("File must contain one sheet with name `wishes`!")
    length(wishes_sheet) > 1 && error("File contains multiple sheets with name `wishes`!")
    rooms_sheet = findall(sheets .== "rooms")
    isnothing(rooms_sheet) && error("File must contain one sheet with name `rooms`!")
    length(rooms_sheet) > 1 && error("File contains multiple sheets with name `rooms`!")

    # get raw Matrix{String} with no empty rows and cols and stripped whitespace
    guests_raw::Matrix{String} = nonempty(strip.(string.(replace(xf["guests"][:], missing => ""))))
    wishes_raw::Matrix{String} = nonempty(strip.(string.(replace(xf["wishes"][:], missing => ""))))
    rooms_raw::Matrix{String} = nonempty(strip.(string.(replace(xf["rooms"][:], missing => ""))))

    return guests_raw, wishes_raw, rooms_raw
end

function get_guests(guests_raw::Matrix{String})

    # error if not enough columns in excel file
    if size(guests_raw, 2) < 2
        error("Not enough columns with data! Sheet `guests` needs to contain the guest " *
            "names in one column and the guest genders another column!")
    end

    # first column should contain the names and the header `name`
    if  guests_raw[begin, begin] !== "name"
        error("First cell in first column of sheet `guests` should contain the names and",
            " the header `name`, instead contains: `", guests_raw[begin, begin], "`")
    end

    # second column should contain the genders and the header `gender`
    if guests_raw[begin, begin+1] !== "gender"
        error("First cell in second column of sheet `guests` should contain the genders ",
            "and the header `gender`, instead contains: `", guests_raw[begin, begin+1], "`")
    end

    # cut the header
    names = @view guests_raw[begin+1:end, begin]
    genders = @view guests_raw[begin+1:end, begin+1]

    # convert raw guests to Vector{Guest}
    guests = Vector{Guest}()
    for i in eachindex(names, genders)
        name = names[i]
        gender = genders[i]

        # error if either one value is missing
        if isempty(name) || isempty(gender)
            error(
                "Missing value in sheet `guests`, guest number ", i, ":",
                "\n  name = ", isempty(name) ? "❓" : name,
                "\n  gender = ", isempty(gender) ? "❓" : gender,
            )
        end

        push!(guests, Guest(name, Symbol(gender)))
    end

    # check for duplicates
    length(guests) > length(unique(guests)) && error("Guest duplicates found!")

    return guests
end

function get_wishes(wishes_raw::Matrix{String}, guests::Vector{Guest})

    # error if not enough columns in excel file
    if size(wishes_raw, 2) < 3
        error("Not enough columns with data! Sheet `wishes` needs to contain the e-mail " *
            "the wish was sent with and the friends in the other columns!")
    end

    # guest names to check if person in wish is part of guests
    guest_names = [g.name for g in guests]

    # cut mail and wishfriends
    mails = @view wishes_raw[:, begin]
    raw_friends = @view wishes_raw[:, begin+1:end]

    # loop over all raw wishes
    wishes = Vector{Wish}()
    for i in eachindex(mails)

        mail = mails[i]
        friends = nonempty(raw_friends[i,:])

        # error if mail is empty
        if isempty(mail)
            error("No e-mail in wish number ", i, " found!")
        end

        # error if not enough friends
        if length(friends) < 2
            error("A wish needs to contain at least 2 friends!\n  See e-mail: ", mail)
        end

        # find corresponding guest_ids of the wish friends
        guest_ids = Vector{Int}()
        for name in friends
            guest_id = findfirst(name .== guest_names)
            if isnothing(guest_id)
                error("Unknown guest in wish:\n  e-mail: ", mail, "\n  name: ", name)
            else
                push!(guest_ids, guest_id)
            end
        end

        # check for same gender
        guests_in_wish = guests[guest_ids]
        genders_equal = allequal([g.gender for g in guests_in_wish])
        if genders_equal
            gender = guests_in_wish[begin].gender
            push!(wishes, Wish(mail, guest_ids, gender))
        else
            error("Mixed gender wish found:\n  e-mail: ", mail, "\n  guests: ",
                guests_in_wish)
        end
    end

    check_for_multiple_wishes(wishes, guests)

    return wishes
end

function check_for_multiple_wishes(wishes::Vector{Wish}, guests::Vector{Guest})

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
            name = guests[guest_id].name
            wish_mails = [w.mail for w in wishes[wishlist]]
            error("Guest ", name," occurs in multiple wishes!\n  e-mails: ", wish_mails)
        end
    end

    return nothing
end

function get_rooms(rooms_raw::Matrix{String})

    # error if not enough columns in rooms_raw
    if size(rooms_raw, 2) < 3
        error("Not enough columns with data! Sheet `rooms` needs to contain the room " *
            "names in one column, room capacity (number of beds) in one column and the " *
            "guest genders in one column!")
    end

    # first column should contain the names and the heading `name`
    if rooms_raw[begin, begin] !== "name"
        error("First cell in first column of sheet `rooms` should contain the name and",
            "the header `name`, instead contains: `", rooms_raw[begin, begin], "`")
    end

    # second column should contain the room capacity and the heading `capacity`
    if rooms_raw[begin, begin+1] !== "capacity"
        error("First cell in second column of sheet `rooms` should contain the capacity ",
            "and the header `capacity`, instead contains: `", rooms_raw[begin, begin+1],
            "`")
    end

    # third column should contain the room gender and the heading `gender`
    if rooms_raw[begin, begin+2] !== "gender"
        error("First cell in third column of sheet `rooms` should contain the room gender",
            " and the header `gender`, instead contains: `", rooms_raw[begin, begin+2], "`")
    end

    # cut the header
    names = @view rooms_raw[begin+1:end, begin]
    capacities = @view rooms_raw[begin+1:end, begin+1]
    genders = @view rooms_raw[begin+1:end, begin+2]

    # convert raw guests to Vector{Guest}
    rooms = Vector{Room}()
    for i in eachindex(names, capacities, genders)
        name = names[i]
        capacity = capacities[i]
        gender = genders[i]

        # error if either one value is missing
        missing_value_check = sum(isempty.((name, capacity, gender)))

        # no value is missing
        if missing_value_check == 0
            push!(rooms, Room(name, parse(Int, capacity), Symbol(gender)))

        # only one or two values are missing
        elseif missing_value_check in (1, 2)
            err_msg = string(
                "Inconsistent missing values in sheet `rooms`, room number ", i, ":",
                "\n  name = ", isempty(name) ? "❓" : name,
                "\n  capacity = ", isempty(capacity) ? "❓" : capacity,
                "\n  gender = ", isempty(gender) ? "❓" : gender
            )
            error(err_msg)
        end
    end

    # check for duplicates
    length(rooms) > length(unique(rooms)) && error("Room duplicates found!")

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
