@time using HappyScheduler
using Test

##
guests_file = joinpath(@__DIR__, "data", "guests10.csv")
wishes_file = joinpath(@__DIR__, "data", "wishes10.csv")
wishes_mg_file = joinpath(@__DIR__, "data", "wishes10_mg.csv") # mixed gender
wishes_mw_file = joinpath(@__DIR__, "data", "wishes10_mw.csv") # multiple wishes
wishes_un_file = joinpath(@__DIR__, "data", "wishes10_un.csv") # unknown guest
rooms_file = joinpath(@__DIR__, "data", "rooms10.csv")

##
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

##
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

##
@test_throws ErrorException wishes_mg = HappyScheduler.get_wishes(wishes_mg_file, guests)
mg_info_file = joinpath(@__DIR__, "data", "mixed_gender_wishes_in_wishes10_mg.txt")
mg_info_file_content = read(mg_info_file, String)
@test occursin("Martha Chung", mg_info_file_content)
@test occursin("mark.white@test.com", mg_info_file_content)

##
@test_throws ErrorException wishes_mw = HappyScheduler.get_wishes(wishes_mw_file, guests)
mw_info_file = joinpath(@__DIR__, "data", "multiple_wishes_in_wishes10_mw.txt")
mw_info_file_content = read(mw_info_file, String)
@test occursin("John Kinder", mw_info_file_content)
@test occursin("mark.white@test.com", mw_info_file_content)
@test occursin("john.kinder@tmobile.com", mw_info_file_content)

##
@test_throws ErrorException wishes_un = HappyScheduler.get_wishes(wishes_un_file, guests)
un_info_file = joinpath(@__DIR__, "data", "unknown_guests_in_wishes10_un.txt")
un_info_file_content = read(un_info_file, String)
@test occursin("Bibi Blocksberg", un_info_file_content)
@test occursin("John Legend", un_info_file_content)
@test occursin("co123@web.com", un_info_file_content)
@test occursin("mark.white@test.com", un_info_file_content)

##
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

##
# simulated_annealing!(rap_m;
#     start_temp=1,
#     minimum_temp=1e-7,
#     β=0.999,
#     n_iter=300,
# );
simulated_annealing!(rap_f;
    start_temp=1,
    minimum_temp=1e-7,
    β=0.999,
    n_iter=300,
);
@test rap_f.fulfilled_wishes == [true]
