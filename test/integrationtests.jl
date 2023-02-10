@testitem "juggle!" begin
    job_file = joinpath(@__DIR__, "data", "job10.xlsx")
    rjj = RoomJugglerJob(job_file)
    juggle!(rjj)
    @test rjj.ropf.fulfilled_wishes == [true]
    @test rjj.ropf.room_id_of_guest[4] == rjj.ropf.room_id_of_guest[2] &&
        rjj.ropf.room_id_of_guest[2] == rjj.ropf.room_id_of_guest[3]
    for room_id in 1:rjj.ropf.n_rooms
        guest_ids = rjj.ropf.guest_ids_of_room[room_id]
        @test length(guest_ids) <= rjj.ropf.rooms[room_id].capacity
        genders = [g.gender for g in rjj.ropf.guests[guest_ids]]
        @test allequal(genders)
    end
    for guest_id in 1:rjj.ropf.n_guests
        room_id = rjj.ropf.room_id_of_guest[guest_id]
        @test guest_id in rjj.ropf.guest_ids_of_room[room_id]
    end
    @test rjj.ropm.fulfilled_wishes == [true]
    @test rjj.ropm.room_id_of_guest[1] == rjj.ropm.room_id_of_guest[5]
    for i in 1:rjj.ropm.n_rooms
        guest_ids = rjj.ropm.guest_ids_of_room[i]
        @test length(guest_ids) <= rjj.ropm.rooms[i].capacity
        genders = [g.gender for g in rjj.ropm.guests[guest_ids]]
        @test allequal(genders)
    end
    for guest_id in 1:rjj.ropm.n_guests
        room_id = rjj.ropm.room_id_of_guest[guest_id]
        @test guest_id in rjj.ropm.guest_ids_of_room[room_id]
    end

    report_excel_file = joinpath(@__DIR__, "temp_report_file.xlsx")
    isfile(report_excel_file) && rm(report_excel_file)
    report(report_excel_file, rjj)
    @test isfile(report_excel_file)

    using XLSX
    xf = XLSX.readxlsx(report_excel_file)
    @test XLSX.sheetnames(xf) == ["guests_report", "wishes_report", "rooms_report"]
    @test xf["guests_report!A1"] == "OVERVIEW OF ALL GUESTS"
    # check first guest
    @test xf["guests_report!A4"] == rjj.ropf.guests[1].name
    @test xf["guests_report!B4"] == string(rjj.ropf.guests[1].gender)
    @test xf["guests_report!C4"] == rjj.ropf.rooms[rjj.ropf.room_id_of_guest[1]].name
    # check second guest
    @test xf["guests_report!A5"] == rjj.ropf.guests[2].name
    @test xf["guests_report!B5"] == string(rjj.ropf.guests[2].gender)
    @test xf["guests_report!C5"] == rjj.ropf.rooms[rjj.ropf.room_id_of_guest[2]].name

    # check first wish
    guest_id = rjj.ropf.wishes[1].guest_ids[1]
    for (i, gid) in enumerate(guest_id)
        cid = 6 + i - 1
        @test xf["wishes_report!B$cid"] == rjj.ropf.guests[gid].name
        @test xf["wishes_report!C$cid"] == string(rjj.ropf.guests[gid].gender)
        @test xf["wishes_report!D$cid"] == rjj.ropf.rooms[rjj.ropf.room_id_of_guest[gid]].name
    end

    # check first room
    guest_ids = rjj.ropf.guest_ids_of_room[1]
    for (i, gid) in enumerate(guest_ids)
        cid = 6 + i - 1
        @test xf["rooms_report!C$cid"] == rjj.ropf.guests[gid].name
        @test xf["rooms_report!D$cid"] == string(rjj.ropf.guests[gid].gender)
    end
    rm(report_excel_file)

    juggle!(rjj)
    @test rjj.ropf.room_id_of_guest[4] == rjj.ropf.room_id_of_guest[2] &&
        rjj.ropf.room_id_of_guest[2] == rjj.ropf.room_id_of_guest[3]
end

@testitem "not fulfillable wishes" begin
    job_file = joinpath(@__DIR__, "data", "job10_nfw.xlsx")
    rjj = RoomJugglerJob(job_file)
    juggle!(rjj; config=JuggleConfig(beta=0.8, n_iter=10))
    @test rjj.ropf.fulfilled_wishes == [false]
end

@testitem "different JuggleConfig" begin
    job_file = joinpath(@__DIR__, "data", "job10.xlsx")
    rjj = RoomJugglerJob(job_file)
    conf_f = JuggleConfig(beta=0.99, n_iter=100)
    conf_m = JuggleConfig(beta=0.1, n_iter=0)
    temp_stdout = joinpath(@__DIR__, "temp_stdout.txt")
    isfile(temp_stdout) && rm(temp_stdout)
    redirect_stdio(stdout=temp_stdout) do
        juggle!(rjj; config=(conf_f, conf_m))
    end
    msg = readlines(temp_stdout)

    # test iterations per temperature
    n_iter_per_temp = findall(x -> startswith(x, "iterations per temp"), msg)
    @test length(n_iter_per_temp) == 2
    @test split(msg[n_iter_per_temp[1]])[end] == string(conf_f.n_iter)
    @test split(msg[n_iter_per_temp[2]])[end] == string(conf_m.n_iter)

    # test total iterations
    total_iter = findall(x -> startswith(x, "planned guest juggles"), msg)
    @test length(total_iter) == 2
    @test split(msg[total_iter[1]])[end] == string(conf_f.n_total_iter)
    @test split(msg[total_iter[2]])[end] == string(conf_m.n_total_iter)

    rm(temp_stdout)
end


@testitem "wrong JuggleConfig" begin
    job_file = joinpath(@__DIR__, "data", "job10.xlsx")
    rjj = RoomJugglerJob(job_file)
    err_msg = "Keyword config must be of type JuggleConfig or Tuple{JuggleConfig, " *
        "JuggleConfig}!"
    @test_throws ErrorException(err_msg) juggle!(rjj; config=(JuggleConfig(),))
end
