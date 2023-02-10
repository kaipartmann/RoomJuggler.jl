@testitem "get_raw_data" begin
    job_file = joinpath(@__DIR__, "data", "job10.xlsx")
    guests_raw, wishes_raw, rooms_raw = RoomJuggler.get_raw_data(job_file)
    @test guests_raw[1:11, 1:2] == [
        "name"             "gender"
        "Martha Chung"     "F"
        "John Kinder"      "M"
        "Cami Horton"      "F"
        "Asa Martell"      "M"
        "Barbara Brown"    "F"
        "Sean Cortez"      "M"
        "Catherine Owens"  "F"
        "Joseph Russell"   "M"
        "Mark White"       "M"
        "Kylie Green"      "F"
    ]
    @test wishes_raw[1:2, 1:4] == [
        "mark.white@test.com"  "Mark White"       "John Kinder"  ""
        "co123@web.com"        "Catherine Owens"  "Cami Horton"  "Barbara Brown"
    ]
    @test rooms_raw[1:5, 1:3] == [
        "name"    "capacity"  "gender"
        "room 1"  "3"          "F"
        "room 2"  "4"          "F"
        "room 3"  "2"          "M"
        "room 4"  "5"          "M"
    ]
end

@testitem "nonempty rows and cols" begin
    let
        m = [
            "" "" ""
            "" "1" ""
            "" "" ""
        ]
        @test RoomJuggler.get_nonempty_cols(m) == [""; "1"; "";;]
        @test RoomJuggler.get_nonempty_rows(m) == ["" "1" ""]
        @test RoomJuggler.nonempty(m) == ["1";;]
    end
    let
        m = [
            "" "" "" "" ""
            "" "1" "" "2" ""
            "" "" "" "" ""
            "" "3" "" "4" ""
            "" "" "" "" ""
        ]
        @test RoomJuggler.get_nonempty_cols(m) == [
            ""   ""
            "1"  "2"
            ""   ""
            "3"  "4"
            ""   ""
        ]
        @test RoomJuggler.get_nonempty_rows(m) == [
            ""  "1"  ""  "2"  ""
            ""  "3"  ""  "4"  ""
        ]
        @test RoomJuggler.nonempty(m) == [
            "1"  "2"
            "3"  "4"
        ]
    end
end

@testitem "get_guests" begin
    job_file = joinpath(@__DIR__, "data", "job10.xlsx")
    guests_raw, _, _ = RoomJuggler.get_raw_data(job_file)
    guests = RoomJuggler.get_guests(guests_raw)
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

@testitem "get_guests not enough columns" begin
    guests_raw = ["Asa Martell";"Barbara Brown";"Sean Cortez";"Catherine Owens";;]
    err_msg = "Not enough columns with data! Sheet `guests` needs to contain the guest " *
        "names in one column and the guest genders another column!"
    @test_throws ErrorException(err_msg) RoomJuggler.get_guests(guests_raw)
end

@testitem "get_guests no header name" begin
    guests_raw = [
        "NamesWrong" "gender"
        "Asa Martell" "F"
        "Barbara Brown" "F"
        "Sean Cortez" "M"
        "Catherine Owens" "F"
    ]
    err_msg = "First cell in first column of sheet `guests` should contain the names and" *
        " the header `name`, instead contains: `NamesWrong`"
    @test_throws ErrorException(err_msg) RoomJuggler.get_guests(guests_raw)
end

@testitem "get_guests no header gender" begin
    guests_raw = [
        "name" "WrongGenderHeader"
        "Asa Martell" "F"
        "Barbara Brown" "F"
        "Sean Cortez" "M"
        "Catherine Owens" "F"
    ]
    err_msg = "First cell in second column of sheet `guests` should contain the genders " *
        "and the header `gender`, instead contains: `WrongGenderHeader`"
    @test_throws ErrorException(err_msg) RoomJuggler.get_guests(guests_raw)
end

@testitem "get_guests missing value" begin
    guests_raw = [
        "name" "gender"
        "Asa Martell" "F"
        "" "F"
        "Sean Cortez" "M"
        "Catherine Owens" "F"
    ]
    err_msg = "Missing value in sheet `guests`, guest number 2:\n  name = ❓\n  gender = F"
    @test_throws ErrorException(err_msg) RoomJuggler.get_guests(guests_raw)
end

@testitem "get_guests duplicates" begin
    guests_raw = [
        "name" "gender"
        "Asa Martell" "F"
        "Asa Martell" "F"
        "Sean Cortez" "M"
        "Catherine Owens" "F"
    ]
    err_msg = "Guest duplicates found!"
    @test_throws ErrorException(err_msg) RoomJuggler.get_guests(guests_raw)
end

@testitem "wishes" begin
    job_file = joinpath(@__DIR__, "data", "job10.xlsx")
    guests_raw, wishes_raw, rooms_raw = RoomJuggler.get_raw_data(job_file)
    guests = RoomJuggler.get_guests(guests_raw)
    wishes = RoomJuggler.get_wishes(wishes_raw, guests)
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

@testitem "wishes not enough columns" begin
    guests = [Guest("Martha Chung", :F)]
    wishes_raw = [
        "mark.white@test.com"  "Mark White"
        "co123@web.com"        "Catherine Owens"
    ]
    err_msg = "Not enough columns with data! Sheet `wishes` needs to contain the e-mail " *
        "the wish was sent with and the friends in the other columns!"
    @test_throws ErrorException(err_msg) RoomJuggler.get_wishes(wishes_raw, guests)
end

@testitem "wishes no email in wish 1" begin
    guests = [Guest("Martha Chung", :F)]
    wishes_raw = [
        ""  "Mark White"       "John Kinder"  ""
    ]
    err_msg = "No e-mail in wish number 1 found!"
    @test_throws ErrorException(err_msg) RoomJuggler.get_wishes(wishes_raw, guests)
end

@testitem "wishes no email in wish 2" begin
    guests = [
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
    wishes_raw = [
        "mark.white@test.com"  "Mark White"       "John Kinder"  ""
        ""        "Catherine Owens"  "Cami Horton"  "Barbara Brown"
    ]
    err_msg = "No e-mail in wish number 2 found!"
    @test_throws ErrorException(err_msg) RoomJuggler.get_wishes(wishes_raw, guests)
end

@testitem "wishes not enough friends" begin
    guests = [
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
    wishes_raw = [
        "mark.white@test.com"  "Mark White"       ""  ""
        "co123@web.com"        "Catherine Owens"  "Cami Horton"  "Barbara Brown"
    ]
    err_msg = "A wish needs to contain at least 2 friends!" *
        "\n  See e-mail: mark.white@test.com"
    @test_throws ErrorException(err_msg) RoomJuggler.get_wishes(wishes_raw, guests)
end

@testitem "mixed gender wishes" begin
    job_file = joinpath(@__DIR__, "data", "job10_mg.xlsx")
    guests_raw, wishes_raw, _ = RoomJuggler.get_raw_data(job_file)
    guests = RoomJuggler.get_guests(guests_raw)
    err_msg = "Mixed gender wish found:\n  e-mail: mark.white@test.com\n  guests: " *
        "RoomJuggler.Guest[RoomJuggler.Guest(\"Mark White\", :M), " *
        "RoomJuggler.Guest(\"John Kinder\", :M), RoomJuggler.Guest(\"Martha Chung\", :F)]"
    err = ErrorException(err_msg)
    @test_throws err wishes_mg = RoomJuggler.get_wishes(wishes_raw, guests)
end

@testitem "multiple wishes per person" begin
    job_file = joinpath(@__DIR__, "data", "job10_mw.xlsx")
    guests_raw, wishes_raw, _ = RoomJuggler.get_raw_data(job_file)
    guests = RoomJuggler.get_guests(guests_raw)
    err_msg = "Guest John Kinder occurs in multiple wishes!\n  " *
        "e-mails: [\"mark.white@test.com\", \"john.kinder@tmobile.com\"]"
    err = ErrorException(err_msg)
    @test_throws err wishes_mg = RoomJuggler.get_wishes(wishes_raw, guests)
end

@testitem "unknown guests" begin
    job_file = joinpath(@__DIR__, "data", "job10_un.xlsx")
    guests_raw, wishes_raw, _ = RoomJuggler.get_raw_data(job_file)
    guests = RoomJuggler.get_guests(guests_raw)
    err_msg = "Unknown guest in wish:\n  e-mail: mark.white@test.com\n  name: John Legend"
    err = ErrorException(err_msg)
    @test_throws err wishes_mg = RoomJuggler.get_wishes(wishes_raw, guests)
end

@testitem "unknown guests manually" begin
    guests = [
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
    wishes_raw = [
        "mark.white@test.com"  "Mark White"       "Tony Stark"  ""
        "co123@web.com"        "Catherine Owens"  "Cami Horton"  "Barbara Brown"
    ]
    err_msg = "Unknown guest in wish:\n  e-mail: mark.white@test.com\n  name: Tony Stark"
    @test_throws ErrorException(err_msg) RoomJuggler.get_wishes(wishes_raw, guests)
end

@testitem "multiple wishes manually" begin
    guests = [
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
    wishes_raw = [
        "mark.white@test.com"  "Mark White"       "John Kinder"  ""
        "mark.white2@test.com"  "Mark White"       "Sean Cortez"  ""
        "co123@web.com"        "Catherine Owens"  "Cami Horton"  "Barbara Brown"
    ]
    err_msg = "Guest Mark White occurs in multiple wishes!\n  " *
        "e-mails: [\"mark.white@test.com\", \"mark.white2@test.com\"]"
    @test_throws ErrorException(err_msg) RoomJuggler.get_wishes(wishes_raw, guests)
end

@testitem "rooms" begin
    job_file = joinpath(@__DIR__, "data", "job10.xlsx")
    _, _, rooms_raw = RoomJuggler.get_raw_data(job_file)
    rooms = RoomJuggler.get_rooms(rooms_raw)
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

@testitem "rooms not enough columns" begin
    rooms_raw = [
        "name" "capacity"
        "room 1" "5"
        "room 2" "4"
    ]
    err_msg = "Not enough columns with data! Sheet `rooms` needs to contain the room " *
        "names in one column, room capacity (number of beds) in one column and the " *
        "guest genders in one column!"
    @test_throws ErrorException(err_msg) RoomJuggler.get_rooms(rooms_raw)
end

@testitem "rooms wrong header name" begin
    rooms_raw = [
        "NameWrong"    "capacity"  "gender"
        "room 1"  "3"         "F"
        "room 2"  "4"         "F"
        "room 3"  "2"         "M"
        "room 4"  "5"         "M"
    ]
    err_msg = "First cell in first column of sheet `rooms` should contain the name and" *
        "the header `name`, instead contains: `NameWrong`"
    @test_throws ErrorException(err_msg) RoomJuggler.get_rooms(rooms_raw)
end

@testitem "rooms wrong header capacity" begin
    rooms_raw = [
        "name"    "CapacityWrong"  "gender"
        "room 1"  "3"         "F"
        "room 2"  "4"         "F"
        "room 3"  "2"         "M"
        "room 4"  "5"         "M"
    ]
    err_msg = "First cell in second column of sheet `rooms` should contain the capacity " *
        "and the header `capacity`, instead contains: `CapacityWrong`"
    @test_throws ErrorException(err_msg) RoomJuggler.get_rooms(rooms_raw)
end

@testitem "rooms wrong header gender" begin
    rooms_raw = [
        "name"    "capacity"  "GenderWrong"
        "room 1"  "3"         "F"
        "room 2"  "4"         "F"
        "room 3"  "2"         "M"
        "room 4"  "5"         "M"
    ]
    err_msg = "First cell in third column of sheet `rooms` should contain the room gender" *
        " and the header `gender`, instead contains: `GenderWrong`"
    @test_throws ErrorException(err_msg) RoomJuggler.get_rooms(rooms_raw)
end

@testitem "rooms missing values" begin
    rooms_raw = [
        "name"    "capacity"  "gender"
        "room 1"  "3"         "F"
        "room 2"  ""          "F"
        "room 3"  "2"         "M"
        "room 4"  "5"         "M"
    ]
    err_msg = "Inconsistent missing values in sheet `rooms`, room number 2:" *
        "\n  name = room 2\n  capacity = ❓\n  gender = F"
    @test_throws ErrorException(err_msg) RoomJuggler.get_rooms(rooms_raw)
end

@testitem "rooms duplicates" begin
    rooms_raw = [
        "name"    "capacity"  "gender"
        "room 1"  "3"         "F"
        "room 2"  "4"         "F"
        "room 3"  "2"         "M"
        "room 4"  "5"         "M"
        "room 4"  "5"         "M"
    ]
    err_msg = "Room duplicates found!"
    @test_throws ErrorException(err_msg) RoomJuggler.get_rooms(rooms_raw)
end

@testitem "not enough beds" begin
    job_file = joinpath(@__DIR__, "data", "job10_neb.xlsx")
    err_msg = "More guests than beds!\n  number of guests = 5\n  number of beds = 4\n"
    err = ErrorException(err_msg)
    @test_throws err RoomJugglerJob(job_file)
end

@testitem "RoomJugglerJob" begin
    job_file = joinpath(@__DIR__, "data", "job10.xlsx")
    rjj = RoomJugglerJob(job_file)
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
