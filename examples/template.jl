@time using XLSX
using Printf, RoomJuggler

xfname = joinpath(@__DIR__, "TemplateRoomJuggler.xlsx")

function get_gwr(xfname)
    xf = XLSX.readxlsx(xfname)

    # guests
    guests_raw = xf["guests"][:][begin+1:end, :]
    guests = Vector{Guest}()
    for row in eachrow(guests_raw)
        name = strip(row[1])
        gender = Symbol(strip(row[2]))
        push!(guests, Guest(name, gender))
    end

    # wishes
    guest_names = [g.name for g in guests]
    unknown_guests = Dict{Int, Vector{String}}()
    wishes_raw = xf["wishes"][:]
    wishes = Vector{Wish}()

    for (wish_id, data) in enumerate(eachrow(wishes_raw))
        mail = data[1]
        names = data[2:end]
        guest_ids = Vector{Int}()
        unknown_guests_in_wish = Vector{String}()
        for name in names
            if !ismissing(name)
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

    # multiple_wishes = check_for_multiple_wishes(wishes, guests)
    # if !isempty(multiple_wishes)
    #     multiple_wishes_info_file = joinpath(
    #         dirname(file),
    #         string("multiple_wishes_in_",splitext(basename(file))[1],".txt")
    #     )
    #     open(multiple_wishes_info_file, "w") do io
    #         write(io, "The following guests made multiple wishes:\n")
    #         for (guest_id, wishlist) in multiple_wishes
    #             println(io)
    #             write(io, guests[guest_id].name, ":\n")
    #             for wish_id in wishlist
    #                 write(io, string("Contained in wish of ", wishes[wish_id].mail), "\n")
    #             end
    #         end
    #     end
    #     msg = @sprintf(
    #         "%d multiple wishes found! Check the file '%s' for more details!",
    #         length(keys(multiple_wishes)),
    #         basename(multiple_wishes_info_file),
    #     )
    #     error(msg)
    # end

    # mixed_gender_wishes = [wish_id for wish_id in eachindex(wishes)
    #     if wishes[wish_id].gender == :MIX]
    # if !isempty(mixed_gender_wishes)
    #     mixed_gender_wishes_info_file = joinpath(
    #         dirname(file),
    #         string("mixed_gender_wishes_in_",splitext(basename(file))[1],".txt")
    #     )
    #     open(mixed_gender_wishes_info_file, "w") do io
    #         write(io, "The following mixed gender wishes appear:\n")
    #         for wish_id in mixed_gender_wishes
    #             println(io)
    #             write(io, string("Wish of ", wishes[wish_id].mail), ":\n")
    #             for guest_id in wishes[wish_id].guest_ids
    #                 write(
    #                     io,
    #                     string(guests[guest_id].gender, ", ", guests[guest_id].name, "\n"),
    #                 )
    #             end
    #         end
    #     end
    #     msg = @sprintf(
    #         "%d mixed gender wishes found! Check the file '%s' for more details!",
    #         length(mixed_gender_wishes),
    #         basename(mixed_gender_wishes_info_file),
    #     )
    #     error(msg)
    # end

    # rooms
    rooms_raw = xf["rooms"][:][begin+1:end, :]
    rooms = Vector{Room}()
    for row in eachrow(rooms_raw)
        name = strip(row[1])
        capacity = row[2]
        gender = Symbol(strip(row[3]))
        push!(rooms, Room(name, capacity, gender))
    end

    return guests, wishes, rooms
end

guests, wishes, rooms = get_gwr(xfname)

XLSX.openxlsx(xfname; mode="rw") do xf
    # !XLSX.hassheet(xf, "results") && XLSX.addsheet!(xf, "results")
    sheet = xf["guests"]
    sheet["C1"] = "roomname"
    sheet["C2", dim=1] = [g.name for g in guests]
end



file = joinpath(@__DIR__, "guests300.csv")
guests_raw, _ = readdlm(file, ';', String; header=true, skipblanks=true)
