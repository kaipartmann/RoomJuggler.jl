@testitem "get_guests" begin
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
    using Logging
    guests_file = joinpath(@__DIR__, "data", "guests10.csv")
    guests = RoomJuggler.get_guests(guests_file)
    wishes_mg_file = joinpath(@__DIR__, "data", "wishes10_mg.csv") # mixed gender
    @test_throws ErrorException wishes_mg = RoomJuggler.get_wishes(
        wishes_mg_file,
        guests,
    )
    io = IOBuffer()
    logger = SimpleLogger(io)
    with_logger(logger) do
        try
            wishes_mg = RoomJuggler.get_wishes(wishes_mg_file, guests)
        catch
        end
    end
    flush(io)
    message = String(take!(io))
    @test occursin("Martha Chung", message)
    @test occursin("Mark White", message)
    @test occursin("John Kinder", message)
    @test occursin("Joseph Russell", message)
    @test occursin("Kylie Green", message)
end

@testitem "multiple wishes per person" begin
    using Logging
    guests_file = joinpath(@__DIR__, "data", "guests10.csv")
    guests = RoomJuggler.get_guests(guests_file)
    wishes_mw_file = joinpath(@__DIR__, "data", "wishes10_mw.csv") # multiple wishes
    @test_throws ErrorException wishes_mw = RoomJuggler.get_wishes(
        wishes_mw_file,
        guests,
    )
    io = IOBuffer()
    logger = SimpleLogger(io)
    with_logger(logger) do
        try
            wishes_mg = RoomJuggler.get_wishes(wishes_mw_file, guests)
        catch
        end
    end
    flush(io)
    message = String(take!(io))
    @test occursin("John Kinder", message)
    @test occursin("mark.white@test.com", message)
    @test occursin("john.kinder@tmobile.com", message)
end

@testitem "unknown guests" begin
    using Logging
    guests_file = joinpath(@__DIR__, "data", "guests10.csv")
    guests = RoomJuggler.get_guests(guests_file)
    wishes_un_file = joinpath(@__DIR__, "data", "wishes10_un.csv") # unknown guest
    @test_throws ErrorException wishes_un = RoomJuggler.get_wishes(
        wishes_un_file,
        guests,
    )
    io = IOBuffer()
    logger = SimpleLogger(io)
    with_logger(logger) do
        try
            wishes_mg = RoomJuggler.get_wishes(wishes_un_file, guests)
        catch
        end
    end
    flush(io)
    message = String(take!(io))
    @test occursin("Bibi Blocksberg", message)
    @test occursin("John Legend", message)
    @test occursin("co123@web.com", message)
    @test occursin("mark.white@test.com", message)
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
    @test String(take!(io)) == "3-person RoomJuggler.Room room 1 (F)"
end

@testitem "not enough beds" begin
    g = joinpath(@__DIR__, "data", "guests10.csv")
    w = joinpath(@__DIR__, "data", "wishes10.csv")
    r = joinpath(@__DIR__, "data", "rooms10_neb.csv")
    @test_throws ErrorException("more guests than beds specified") RoomJugglerJob(g, w, r)
end

@testitem "RoomJugglerJob" begin
    g = joinpath(@__DIR__, "data", "guests10.csv")
    w = joinpath(@__DIR__, "data", "wishes10.csv")
    r = joinpath(@__DIR__, "data", "rooms10.csv")
    rjj = RoomJugglerJob(g, w, r)
    @test rjj.n_guests == 10
    @test rjj.n_wishes == 2
    @test rjj.n_rooms == 4
    @test rjj.n_beds == 14
    @test rjj.ropf.n_guests == 5
    @test rjj.ropf.n_wishes == 1
    @test rjj.ropf.n_rooms == 2
    @test rjj.ropf.n_beds == 7
    @test rjj.ropf.max_happiness == 6
    guests_f_manually = [
        Guest("Martha Chung", :F),
        Guest("Cami Horton", :F),
        Guest("Barbara Brown", :F),
        Guest("Catherine Owens", :F),
        Guest("Kylie Green", :F),
    ]
    @test length(rjj.ropf.guests) == length(guests_f_manually)
    for (i, guest) in enumerate(guests_f_manually)
        @test rjj.ropf.guests[i].name == guest.name
        @test rjj.ropf.guests[i].gender == guest.gender
    end
    @test rjj.ropm.n_guests == 5
    @test rjj.ropm.n_wishes == 1
    @test rjj.ropm.n_rooms == 2
    @test rjj.ropm.n_beds == 7
    @test rjj.ropm.max_happiness == 2
    guests_m_manually = [
        Guest("John Kinder", :M),
        Guest("Asa Martell", :M),
        Guest("Sean Cortez", :M),
        Guest("Joseph Russell", :M),
        Guest("Mark White", :M),
    ]
    @test length(rjj.ropm.guests) == length(guests_m_manually)
    for (i, guest) in enumerate(guests_m_manually)
        @test rjj.ropm.guests[i].name == guest.name
        @test rjj.ropm.guests[i].gender == guest.gender
    end
    io = IOBuffer()
    show(IOContext(io), "text/plain", rjj)
    @test String(take!(io)) == "RoomJuggler.RoomJugglerJob:\n4 rooms\n  2 females\n  2 " *
        "males\n14 beds\n  7 females\n  7 males\n10 guests\n  5 females\n  5 males\n2 " *
        "wishes\n  1 females\n  1 males\n"
end

@testitem "JuggleConfig" begin
    @test_throws BoundsError JuggleConfig(; n_iter=300, beta=1.1, t_0=1.0, t_min=1e-7)
end
