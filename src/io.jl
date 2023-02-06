function log_init()
    printstyled("-"^67 * "\n"; color=:blue, bold=true)
    println()
    printstyled(BANNER; color=:blue)
    printstyled("-"^67 * "\n"; color=:blue, bold=true)
    printstyled(
        "     SOLVING A ROOM OCCUPANCY PROBLEM WITH SIMULATED ANNEALING\n";
        color=:blue,
        bold=true,
    )
    printstyled("-"^67 * "\n"; color=:blue, bold=true)
    return nothing
end

function log_start(config::JuggleConfig, max_happiness::Int)
    @printf("start temperature:      %15g\n", config.t_0)
    @printf("minimum temperature:    %15g\n", config.t_min)
    @printf("iterations per temp.:   %15d\n", config.n_iter)
    @printf("planned guest juggles:  %15d\n", config.n_total_iter)
    @printf("maximum happiness:      %15d\n", max_happiness)
    return nothing
end

function log_results(rop::RoomOccupancyProblem, happiness::Int, n_total_iter::Int)
    @printf("total guest switches:   %15d\n", n_total_iter)
    @printf("happiness:              %15d\n", abs(happiness))
    if abs(happiness) == rop.max_happiness
        print("all wishes are fulfilled!")
        printstyled("      (━☞´◔‿ゝ◔`)━☞    ᕙᓄ(☉ਊ☉)ᓄᕗ\n", color=:blue)
    else
        fulfilled_wishes_percent = 100 * abs(happiness) / rop.max_happiness
        @printf("%.2f %% of all wishes are fulfilled!", fulfilled_wishes_percent)
        printstyled("      (͡o‿O͡)\n", color=:blue)
        n_fulfilled_wishes = length(findall(rop.fulfilled_wishes .== true))
        n_unfulfilled_wishes = length(findall(rop.fulfilled_wishes .== false))
        @assert rop.n_wishes == n_fulfilled_wishes + n_unfulfilled_wishes
        @printf("  %d wishes fulfilled\n", n_fulfilled_wishes)
        @printf("  %d wishes not fulfilled\n", n_unfulfilled_wishes)
        println()
        println("adjust the parameters in JuggleConfig and try again!")
    end
end

function export_wish_overview(io::IO, rop::RoomOccupancyProblem)
    for (wish_id, wish) in enumerate(rop.wishes)
        wish_checkmark = rop.fulfilled_wishes[wish_id] ? "✔︎" : "✘"
        @printf(io, "%s %s (%s):\n", wish_checkmark, wish.mail, wish.gender)
        for guest_id in wish.guest_ids
            guest_name = rop.guests[guest_id].name
            guest_gender = rop.guests[guest_id].gender
            guest_room_name = rop.rooms[rop.room_id_of_guest[guest_id]].name
            @printf(io, "    %s (%s) - %s\n", guest_name, guest_gender, guest_room_name)
        end
        println(io)
    end
    return nothing
end

function export_room_overview(io::IO, rop::RoomOccupancyProblem)
    for (room_id, room) in enumerate(rop.rooms)
        @printf(io, "%s (%s, %d beds):\n", room.name, room.gender, room.capacity)
        guest_ids = rop.guest_ids_of_room[room_id]
        for (bed_nr, guest_id) in enumerate(guest_ids)
            guest_name = rop.guests[guest_id].name
            guest_gender = rop.guests[guest_id].gender
            @printf(io, "    %d. %s (%s)\n", bed_nr, guest_name, guest_gender)
        end
        if length(guest_ids) < room.capacity
            for bed_nr in range(start=length(guest_ids)+1, stop=room.capacity)
                @printf(io, "    %d. ---\n", bed_nr)
            end
        end
        println(io)
    end

    return nothing
end

function export_guests_csv(file::String, rjj::RoomJugglerJob)
    open(file, "w") do io
        println(io, "name;gender;room")

        # females
        for (guest_id, guest) in enumerate(rjj.ropf.guests)
            room_name = rjj.ropf.rooms[rjj.ropf.room_id_of_guest[guest_id]].name
            @printf(io, "%s;%s;%s\n", guest.name, guest.gender, room_name)
        end

        # males
        for (guest_id, guest) in enumerate(rjj.ropm.guests)
            room_name = rjj.ropm.rooms[rjj.ropm.room_id_of_guest[guest_id]].name
            @printf(io, "%s;%s;%s\n", guest.name, guest.gender, room_name)
        end
    end

    return nothing
end

function export_report(file::String, rjj::RoomJugglerJob)
    open(file, "w") do io
        println(io, "="^67)
        println(io, "OVERVIEW OF ALL WISHES")
        println(io, "="^67)
        println(io, "\n--- FEMALES: ---\n")
        export_wish_overview(io, rjj.ropf)
        println(io, "\n--- MALES: ---\n")
        export_wish_overview(io, rjj.ropm)
        println(io, "="^67)
        println(io, "OVERVIEW OF ALL ROOMS")
        println(io, "="^67)
        println(io, "\n--- FEMALES: ---\n")
        export_room_overview(io, rjj.ropf)
        println(io, "\n--- MALES: ---\n")
        export_room_overview(io, rjj.ropm)
    end

    return nothing
end

function export_results(dir::String, rjj::RoomJugglerJob; force::Bool=false)
    # if dir exists, check if overwriting is allowed
    if isdir(dir)
        if !force
            error("directory $dir exists! use keyword argument force=true to overwrite")
        end
    else
        # otherwise create dir
        mkpath(dir)
    end

    # export csv file for guests and report
    export_guests_csv(joinpath(dir, "guests.csv"), rjj)
    export_report(joinpath(dir, "report.txt"), rjj)

    println("✔︎ results exported to $dir")

    return nothing
end
