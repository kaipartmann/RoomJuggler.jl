@testitem "guests" begin
    using RoomJuggler
    guests_file = joinpath(@__DIR__, "data", "guests10.csv")
    guests = RoomJuggler.get_guests(guests_file)
    guests_manually = [
        Guest("Martha Chung", :F),
        Guest("John Kinder", :M),
        Guest("Cami Horton", :F),
        Guest("Asa Martell", :M),
        Guest("Barbara Brown", :F),
        Guest("Sean Cortez", :M),
        Guest("Catherine Owens", :F),
        Guest("Joseph Russell", :M),
        Guest("Mark White", :M),
        Guest("Kylie Green", :F),
    ]
    @test length(guests) == length(guests_manually)
    for (i, guest) in enumerate(guests_manually)
        @test guests[i].name == guest.name
        @test guests[i].gender == guest.gender
    end
    io = IOBuffer()
    show(IOContext(io), "text/plain", guests_manually[1])
    @test String(take!(io)) == "RoomJuggler.Guest: Martha Chung (F)"
end

@testitem "wishes" begin
    guests_file = joinpath(@__DIR__, "data", "guests10.csv")
    guests = RoomJuggler.get_guests(guests_file)
    wishes_file = joinpath(@__DIR__, "data", "wishes10.csv")
    wishes = RoomJuggler.get_wishes(wishes_file, guests)
    wishes_manually = [
        Wish("mark.white@test.com", [9, 2], :M),
        Wish("co123@web.com", [7, 3, 5], :F),
    ]
    @test length(wishes) == length(wishes_manually)
    for (i, wish) in enumerate(wishes_manually)
        @test wishes[i].mail == wish.mail
        @test wishes[i].guest_ids == wish.guest_ids
        @test wishes[i].gender == wish.gender
    end
    io = IOBuffer()
    show(IOContext(io), "text/plain", wishes_manually[1])
    @test String(take!(io)) == "2-person RoomJuggler.Wish from mark.white@test.com"
end

@testitem "mixed gender wishes" begin
    mg_info_file = joinpath(@__DIR__, "data", "mixed_gender_wishes_in_wishes10_mg.txt")
    if isfile(mg_info_file)
        rm(mg_info_file, force=true)
    end
    guests_file = joinpath(@__DIR__, "data", "guests10.csv")
    guests = RoomJuggler.get_guests(guests_file)
    wishes_mg_file = joinpath(@__DIR__, "data", "wishes10_mg.csv") # mixed gender
    @test_throws ErrorException wishes_mg = RoomJuggler.get_wishes(
        wishes_mg_file,
        guests,
    )
    @test isfile(mg_info_file)
    mg_info_file_content = read(mg_info_file, String)
    @test occursin("Martha Chung", mg_info_file_content)
    @test occursin("mark.white@test.com", mg_info_file_content)
    rm(mg_info_file, force=true)
end

@testitem "multiple wishes per person" begin
    mw_info_file = joinpath(@__DIR__, "data", "multiple_wishes_in_wishes10_mw.txt")
    if isfile(mw_info_file)
        rm(mw_info_file, force=true)
    end
    guests_file = joinpath(@__DIR__, "data", "guests10.csv")
    guests = RoomJuggler.get_guests(guests_file)
    wishes_mw_file = joinpath(@__DIR__, "data", "wishes10_mw.csv") # multiple wishes
    @test_throws ErrorException wishes_mw = RoomJuggler.get_wishes(
        wishes_mw_file,
        guests,
    )
    @test isfile(mw_info_file)
    mw_info_file_content = read(mw_info_file, String)
    @test occursin("John Kinder", mw_info_file_content)
    @test occursin("mark.white@test.com", mw_info_file_content)
    @test occursin("john.kinder@tmobile.com", mw_info_file_content)
    rm(mw_info_file, force=true)
end

@testitem "unknown guests" begin
    un_info_file = joinpath(@__DIR__, "data", "unknown_guests_in_wishes10_un.txt")
    if isfile(un_info_file)
        rm(un_info_file, force=true)
    end
    guests_file = joinpath(@__DIR__, "data", "guests10.csv")
    guests = RoomJuggler.get_guests(guests_file)
    wishes_un_file = joinpath(@__DIR__, "data", "wishes10_un.csv") # unknown guest
    @test_throws ErrorException wishes_un = RoomJuggler.get_wishes(
        wishes_un_file,
        guests,
    )
    @test isfile(un_info_file)
    un_info_file_content = read(un_info_file, String)
    @test occursin("Bibi Blocksberg", un_info_file_content)
    @test occursin("John Legend", un_info_file_content)
    @test occursin("co123@web.com", un_info_file_content)
    @test occursin("mark.white@test.com", un_info_file_content)
    rm(un_info_file, force=true)
end

@testitem "rooms" begin
    rooms_file = joinpath(@__DIR__, "data", "rooms10.csv")
    rooms = RoomJuggler.get_rooms(rooms_file)
    rooms_manually = [
        Room("room 1", 3, :F),
        Room("room 2", 4, :F),
        Room("room 3", 2, :M),
        Room("room 4", 5, :M),
    ]
    @test length(rooms) == length(rooms_manually)
    for (i, room) in enumerate(rooms_manually)
        @test rooms[i].name == room.name
        @test rooms[i].capacity == room.capacity
        @test rooms[i].gender == room.gender
    end
    io = IOBuffer()
    show(IOContext(io), "text/plain", rooms_manually[1])
    @test String(take!(io)) == "3-person RoomJuggler.Room with name: room 1"
end

@testitem "not enough beds" begin
    guests_file = joinpath(@__DIR__, "data", "guests10.csv")
    wishes_file = joinpath(@__DIR__, "data", "wishes10.csv")
    rooms_file = joinpath(@__DIR__, "data", "rooms10_neb.csv")
    gwrf, gwrm = get_gwr_split_genders(guests_file, wishes_file, rooms_file)
    @test_throws ErrorException RoomAllocationProblem(gwrf...)
    @test_throws ErrorException RoomAllocationProblem(gwrm...)
end

@testitem "get_gwr" begin
    guests_file = joinpath(@__DIR__, "data", "guests10.csv")
    wishes_file = joinpath(@__DIR__, "data", "wishes10.csv")
    rooms_file = joinpath(@__DIR__, "data", "rooms10.csv")
    gwr = get_gwr(guests_file, wishes_file, rooms_file)
    @test length(gwr[1]) == 10
    @test length(gwr[2]) == 2
    @test length(gwr[3]) == 4
end

@testitem "gender separated raps" begin
    guests_file = joinpath(@__DIR__, "data", "guests10.csv")
    wishes_file = joinpath(@__DIR__, "data", "wishes10.csv")
    rooms_file = joinpath(@__DIR__, "data", "rooms10.csv")
    gwrf, gwrm = get_gwr_split_genders(guests_file, wishes_file, rooms_file)
    rapf = RoomAllocationProblem(gwrf...)
    @test rapf.n_guests == 5
    @test rapf.n_wishes == 1
    @test rapf.n_rooms == 2
    @test rapf.n_beds == 7
    @test rapf.max_happiness == 6
    guests_f_manually = [
        Guest("Martha Chung", :F),
        Guest("Cami Horton", :F),
        Guest("Barbara Brown", :F),
        Guest("Catherine Owens", :F),
        Guest("Kylie Green", :F),
    ]
    @test length(rapf.guests) == length(guests_f_manually)
    for (i, guest) in enumerate(guests_f_manually)
        @test rapf.guests[i].name == guest.name
        @test rapf.guests[i].gender == guest.gender
    end
    io = IOBuffer()
    show(IOContext(io), "text/plain", rapf)
    @test String(take!(io)) == "2-room RoomJuggler.RoomAllocationProblem:" *
        "\n  7 beds\n  5 guests\n  1 wishes"
    rapm = RoomAllocationProblem(gwrm...)
    @test rapm.n_guests == 5
    @test rapm.n_wishes == 1
    @test rapm.n_rooms == 2
    @test rapm.n_beds == 7
    @test rapm.max_happiness == 2
    guests_m_manually = [
        Guest("John Kinder", :M),
        Guest("Asa Martell", :M),
        Guest("Sean Cortez", :M),
        Guest("Joseph Russell", :M),
        Guest("Mark White", :M),
    ]
    @test length(rapm.guests) == length(guests_m_manually)
    for (i, guest) in enumerate(guests_m_manually)
        @test rapm.guests[i].name == guest.name
        @test rapm.guests[i].gender == guest.gender
    end
    io = IOBuffer()
    show(IOContext(io), "text/plain", rapm)
    @test String(take!(io)) == "2-room RoomJuggler.RoomAllocationProblem:" *
        "\n  7 beds\n  5 guests\n  1 wishes"
end

@testitem "simulated annealing" begin
    guests_file = joinpath(@__DIR__, "data", "guests10.csv")
    wishes_file = joinpath(@__DIR__, "data", "wishes10.csv")
    rooms_file = joinpath(@__DIR__, "data", "rooms10.csv")
    gwrf, gwrm = get_gwr_split_genders(guests_file, wishes_file, rooms_file)
    rapf = RoomAllocationProblem(gwrf...)
    simulated_annealing!(rapf;
        start_temp=1,
        minimum_temp=1e-7,
        β=0.999,
        n_iter=300,
    )
    @test rapf.fulfilled_wishes == [true]
    @test rapf.room_id_of_guest[4] == rapf.room_id_of_guest[2] &&
        rapf.room_id_of_guest[2] == rapf.room_id_of_guest[3]
    for room_id in 1:rapf.n_rooms
        guest_ids = rapf.guest_ids_of_room[room_id]
        @test length(guest_ids) <= rapf.rooms[room_id].capacity
        genders = [g.gender for g in rapf.guests[guest_ids]]
        @test allequal(genders)
    end
    for guest_id in 1:rapf.n_guests
        room_id = rapf.room_id_of_guest[guest_id]
        @test guest_id in rapf.guest_ids_of_room[room_id]
    end
    resfile_f_guests = joinpath(@__DIR__, "res_f_guests.csv")
    resfile_f_wishes = joinpath(@__DIR__, "res_f_wishes.txt")
    resfile_f_rooms = joinpath(@__DIR__, "res_f_rooms.txt")
    isfile(resfile_f_guests) && rm(resfile_f_guests)
    isfile(resfile_f_wishes) && rm(resfile_f_wishes)
    isfile(resfile_f_rooms) && rm(resfile_f_rooms)
    export_results(rapf; dir=@__DIR__, prefix="res_f_")
    @test isfile(resfile_f_guests)
    @test isfile(resfile_f_wishes)
    @test isfile(resfile_f_rooms)
    rm(resfile_f_guests)
    rm(resfile_f_wishes)
    rm(resfile_f_rooms)
    rapm = RoomAllocationProblem(gwrm...)
    simulated_annealing!(rapm;
        start_temp=1,
        minimum_temp=1e-7,
        β=0.999,
        n_iter=300,
    )
    @test rapm.fulfilled_wishes == [true]
    @test rapm.room_id_of_guest[1] == rapm.room_id_of_guest[5]
    for i in 1:rapm.n_rooms
        guest_ids = rapm.guest_ids_of_room[i]
        @test length(guest_ids) <= rapm.rooms[i].capacity
        genders = [g.gender for g in rapm.guests[guest_ids]]
        @test allequal(genders)
    end
    for guest_id in 1:rapm.n_guests
        room_id = rapm.room_id_of_guest[guest_id]
        @test guest_id in rapm.guest_ids_of_room[room_id]
    end
    resfile_m_guests = joinpath(@__DIR__, "res_m_guests.csv")
    resfile_m_wishes = joinpath(@__DIR__, "res_m_wishes.txt")
    resfile_m_rooms = joinpath(@__DIR__, "res_m_rooms.txt")
    isfile(resfile_m_guests) && rm(resfile_m_guests)
    isfile(resfile_m_wishes) && rm(resfile_m_wishes)
    isfile(resfile_m_rooms) && rm(resfile_m_rooms)
    export_results(rapm; dir=@__DIR__, prefix="res_m_")
    @test isfile(resfile_m_guests)
    @test isfile(resfile_m_wishes)
    @test isfile(resfile_m_rooms)
    rm(resfile_m_guests)
    rm(resfile_m_wishes)
    rm(resfile_m_rooms)
    @test_throws ErrorException simulated_annealing!(rapm;
        start_temp=1,
        minimum_temp=1e-7,
        β=1.1, # Infinity-Loop!
        n_iter=300,
    )
end

@testitem "not fulfillable wishes" begin
    guests_file = joinpath(@__DIR__, "data", "guests10.csv")
    wishes_file = joinpath(@__DIR__, "data", "wishes10_nfw.csv")
    rooms_file = joinpath(@__DIR__, "data", "rooms10.csv")
    gwrf, _ = get_gwr_split_genders(guests_file, wishes_file, rooms_file)
    rapf = RoomAllocationProblem(gwrf...)
    simulated_annealing!(rapf;
        start_temp=1,
        minimum_temp=1e-7,
        β=0.8,
        n_iter=10,
    )
    @test rapf.fulfilled_wishes == [false]
end
