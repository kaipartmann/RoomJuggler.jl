using HappyScheduler
using Test

##
guests_file = joinpath(@__DIR__, "data", "guests10.csv")
wishes_file = joinpath(@__DIR__, "data", "wishes10.csv")
wishes_mg_file = joinpath(@__DIR__, "data", "wishes10_mg.csv") # mixed gender
wishes_mw_file = joinpath(@__DIR__, "data", "wishes10_mw.csv") # multiple wishes
wishes_un_file = joinpath(@__DIR__, "data", "wishes10_un.csv") # unknown guest
rooms_file = joinpath(@__DIR__, "data", "rooms10.csv")

##
@testitem "guests" begin
    guests_file = joinpath(@__DIR__, "data", "guests10.csv")
    guests = HappyScheduler.get_guests(guests_file)
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
end

##
@testitem "wishes" begin
    guests_file = joinpath(@__DIR__, "data", "guests10.csv")
    guests = HappyScheduler.get_guests(guests_file)
    wishes_file = joinpath(@__DIR__, "data", "wishes10.csv")
    wishes = HappyScheduler.get_wishes(wishes_file, guests)
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
end

##
@testitem "mixed gender wishes" begin
    mg_info_file = joinpath(@__DIR__, "data", "mixed_gender_wishes_in_wishes10_mg.txt")
    if isfile(mg_info_file)
        rm(mg_info_file, force=true)
    end
    guests_file = joinpath(@__DIR__, "data", "guests10.csv")
    guests = HappyScheduler.get_guests(guests_file)
    wishes_mg_file = joinpath(@__DIR__, "data", "wishes10_mg.csv") # mixed gender
    @test_throws ErrorException wishes_mg = HappyScheduler.get_wishes(
        wishes_mg_file,
        guests,
    )
    @test isfile(mg_info_file)
    mg_info_file_content = read(mg_info_file, String)
    @test occursin("Martha Chung", mg_info_file_content)
    @test occursin("mark.white@test.com", mg_info_file_content)
    rm(mg_info_file, force=true)
end

##
@testitem "multiple wishes per person" begin
    mw_info_file = joinpath(@__DIR__, "data", "multiple_wishes_in_wishes10_mw.txt")
    if isfile(mw_info_file)
        rm(mw_info_file, force=true)
    end
    guests_file = joinpath(@__DIR__, "data", "guests10.csv")
    guests = HappyScheduler.get_guests(guests_file)
    wishes_mw_file = joinpath(@__DIR__, "data", "wishes10_mw.csv") # multiple wishes
    @test_throws ErrorException wishes_mw = HappyScheduler.get_wishes(
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

##
@testitem "unknown guests" begin
    un_info_file = joinpath(@__DIR__, "data", "unknown_guests_in_wishes10_un.txt")
    if isfile(un_info_file)
        rm(un_info_file, force=true)
    end
    guests_file = joinpath(@__DIR__, "data", "guests10.csv")
    guests = HappyScheduler.get_guests(guests_file)
    wishes_un_file = joinpath(@__DIR__, "data", "wishes10_un.csv") # unknown guest
    @test_throws ErrorException wishes_un = HappyScheduler.get_wishes(
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

##
@testitem "gender separated raps" begin
    guests_file = joinpath(@__DIR__, "data", "guests10.csv")
    wishes_file = joinpath(@__DIR__, "data", "wishes10.csv")
    rooms_file = joinpath(@__DIR__, "data", "rooms10.csv")
    rap_f, rap_m = gender_separated_raps(guests_file, wishes_file, rooms_file)
    @test rap_f.n_guests == 5
    @test rap_f.n_wishes == 1
    @test rap_f.n_rooms == 2
    @test rap_f.n_beds == 7
    @test rap_f.max_happiness == 6
    guests_f_manually = [
        Guest("Martha Chung", :F),
        Guest("Cami Horton", :F),
        Guest("Barbara Brown", :F),
        Guest("Catherine Owens", :F),
        Guest("Kylie Green", :F),
    ]
    @test length(rap_f.guests) == length(guests_f_manually)
    for (i, guest) in enumerate(guests_f_manually)
        @test rap_f.guests[i].name == guest.name
        @test rap_f.guests[i].gender == guest.gender
    end
    @test rap_m.n_guests == 5
    @test rap_m.n_wishes == 1
    @test rap_m.n_rooms == 2
    @test rap_m.n_beds == 7
    @test rap_m.max_happiness == 2
    guests_m_manually = [
        Guest("John Kinder", :M),
        Guest("Asa Martell", :M),
        Guest("Sean Cortez", :M),
        Guest("Joseph Russell", :M),
        Guest("Mark White", :M),
    ]
    @test length(rap_m.guests) == length(guests_m_manually)
    for (i, guest) in enumerate(guests_m_manually)
        @test rap_m.guests[i].name == guest.name
        @test rap_m.guests[i].gender == guest.gender
    end
end

##
@testitem "simulated annealing" begin
    guests_file = joinpath(@__DIR__, "data", "guests10.csv")
    wishes_file = joinpath(@__DIR__, "data", "wishes10.csv")
    rooms_file = joinpath(@__DIR__, "data", "rooms10.csv")
    rap_f, rap_m = gender_separated_raps(guests_file, wishes_file, rooms_file)
    simulated_annealing!(rap_f;
        start_temp=1,
        minimum_temp=1e-7,
        β=0.999,
        n_iter=300,
    );
    @test rap_f.fulfilled_wishes == [true]
    @test rap_f.room_id_of_guest[4] == rap_f.room_id_of_guest[2] &&
        rap_f.room_id_of_guest[2] == rap_f.room_id_of_guest[3]
    for room_id in 1:rap_f.n_rooms
        guest_ids = rap_f.guest_ids_of_room[room_id]
        @test length(guest_ids) <= rap_f.rooms[room_id].capacity
        genders = [g.gender for g in rap_f.guests[guest_ids]]
        @test allequal(genders)
    end
    for guest_id in 1:rap_f.n_guests
        room_id = rap_f.room_id_of_guest[guest_id]
        @test guest_id in rap_f.guest_ids_of_room[room_id]
    end
    simulated_annealing!(rap_m;
        start_temp=1,
        minimum_temp=1e-7,
        β=0.999,
        n_iter=300,
    );
    @test rap_m.fulfilled_wishes == [true]
    @test rap_m.room_id_of_guest[1] == rap_m.room_id_of_guest[5]
    for i in 1:rap_m.n_rooms
        guest_ids = rap_m.guest_ids_of_room[i]
        @test length(guest_ids) <= rap_m.rooms[i].capacity
        genders = [g.gender for g in rap_m.guests[guest_ids]]
        @test allequal(genders)
    end
    for guest_id in 1:rap_m.n_guests
        room_id = rap_m.room_id_of_guest[guest_id]
        @test guest_id in rap_m.guest_ids_of_room[room_id]
    end
end
