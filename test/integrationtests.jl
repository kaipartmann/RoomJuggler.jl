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
    results_dir = joinpath(@__DIR__, "temp_results")
    isdir(results_dir) && rm(results_dir; recursive=true)
    export_results(results_dir, rjj)
    @test isfile(joinpath(@__DIR__, "temp_results", "guests.csv"))
    @test isfile(joinpath(@__DIR__, "temp_results", "report.txt"))
    rm(results_dir; recursive=true)
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
