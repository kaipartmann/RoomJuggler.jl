const BANNER = raw"""
      ░▒█▀▀▄░▄▀▀▄░▄▀▀▄░█▀▄▀█░░░░▒█░█░▒█░█▀▀▀░█▀▀▀░█░░█▀▀░█▀▀▄
      ░▒█▄▄▀░█░░█░█░░█░█░▀░█░░░░▒█░█░▒█░█░▀▄░█░▀▄░█░░█▀▀░█▄▄▀
      ░▒█░▒█░░▀▀░░░▀▀░░▀░░▒▀░▒█▄▄█░░▀▀▀░▀▀▀▀░▀▀▀▀░▀▀░▀▀▀░▀░▀▀
"""

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
        printstyled("      (͡o‿O͡)\n\n", color=:blue)
        printstyled("adjust the parameters in JuggleConfig and try again!\n";
            color=:red,
            bold=true,
        )
    end
end

function wishes_report(rop::RoomOccupancyProblem)
    report = Vector{Matrix{String}}()

    for wish_id in eachindex(rop.wishes)
        status = rop.fulfilled_wishes[wish_id] ? "✔" : "✖"
        mail = rop.wishes[wish_id].mail
        guest_ids = rop.wishes[wish_id].guest_ids
        guests = rop.guests[guest_ids]
        names = [g.name for g in guests]
        genders = [string(g.gender) for g in guests]
        rooms = rop.rooms[rop.room_id_of_guest[guest_ids]]
        room_names = [r.name for r in rooms]

        m = fill("", length(guest_ids) + 2, 4)
        m[1, 1] = status * " " * mail
        m[2:end-1, 2] = names
        m[2:end-1, 3] = genders
        m[2:end-1, 4] = room_names

        push!(report, m)
    end

    return reduce(vcat, report)
end

function wishes_report(rjj::RoomJugglerJob)
    header = [
        "OVERVIEW OF ALL WISHES" "" "" ""
    ]
    females_header = [
        "" "" "" ""
        "--- FEMALES: ---" "" "" ""
        "" "" "" ""
    ]
    females_report = wishes_report(rjj.ropf)
    males_header = [
        "" "" "" ""
        "--- MALES: ---" "" "" ""
        "" "" "" ""
    ]
    males_report = wishes_report(rjj.ropm)
    report = [header, females_header, females_report, males_header, males_report]

    return reduce(vcat, report)
end

function rooms_report(rop::RoomOccupancyProblem)
    report = Vector{Matrix{String}}()

    for room_id in eachindex(rop.rooms)
        room_name = rop.rooms[room_id].name
        n_beds = rop.rooms[room_id].capacity

        guest_ids = rop.guest_ids_of_room[room_id]
        guests = rop.guests[guest_ids]
        guest_numbers = [string(i, ".") for i in 1:n_beds]
        guest_names = fill("---", n_beds)
        guest_names[1:length(guest_ids)] = [g.name for g in guests]
        guest_genders = fill("", n_beds)
        guest_genders[1:length(guest_ids)] = [string(g.gender) for g in guests]

        m = fill("", n_beds + 2, 4)
        m[1, 1] = room_name
        m[2:end-1, 2] = guest_numbers
        m[2:end-1, 3] = guest_names
        m[2:end-1, 4] = guest_genders

        push!(report, m)
    end

    return reduce(vcat, report)
end

function rooms_report(rjj::RoomJugglerJob)
    header = [
        "OVERVIEW OF ALL ROOMS" "" "" ""
    ]
    females_header = [
        "" "" "" ""
        "--- FEMALES: ---" "" "" ""
        "" "" "" ""
    ]
    females_report = rooms_report(rjj.ropf)
    males_header = [
        "" "" "" ""
        "--- MALES: ---" "" "" ""
        "" "" "" ""
    ]
    males_report = rooms_report(rjj.ropm)
    report = [header, females_header, females_report, males_header, males_report]

    return reduce(vcat, report)
end

function guests_report(rop::RoomOccupancyProblem)
    report = fill("", rop.n_guests, 3)
    report[:, 1] = [g.name for g in rop.guests]
    report[:, 2] = [string(g.gender) for g in rop.guests]
    report[:, 3] = [r.name for r in rop.rooms[rop.room_id_of_guest]]

    return report
end

function guests_report(rjj::RoomJugglerJob)
    header = [
        "OVERVIEW OF ALL GUESTS" "" ""
        "" "" ""
        "name" "gender" "room"
    ]
    report_female = guests_report(rjj.ropf)
    report_male = guests_report(rjj.ropm)

    return reduce(vcat, [header, report_female, report_male])
end

function report(excel_file::String, rjj::RoomJugglerJob)
    XLSX.openxlsx(excel_file, mode="w") do xf
        # guests
        gsheet = xf[1]
        XLSX.rename!(gsheet, "guests_report")
        gsheet["A1"] = guests_report(rjj)

        # wishes
        XLSX.addsheet!(xf, "wishes_report")
        wsheet = xf["wishes_report"]
        wsheet["A1"] = wishes_report(rjj)

        # rooms
        XLSX.addsheet!(xf, "rooms_report")
        rsheet = xf["rooms_report"]
        rsheet["A1"] = rooms_report(rjj)
    end

    return nothing
end
