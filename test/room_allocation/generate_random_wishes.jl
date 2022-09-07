using HappyScheduler
using DelimitedFiles
using Random

function get_random_wishes(guests, max_wish_size::Int=8)
    n = length(guests)
    guest_names = [g.name for g in guests]
    wishes = Vector{Vector{Int}}(undef, 0)
    isinwish = Set{Int}()
    for _ in 1:floor(n/max_wish_size)
        n_persons = rand(2:max_wish_size)
        guest_ids = zeros(Int, n_persons)
        for i in 1:n_persons
            idnotfound = true
            id = 0
            while idnotfound
                id = rand(1:n)
                if !(id in isinwish)
                    push!(isinwish, id)
                    idnotfound = false
                end
            end
            guest_ids[i] = id
        end
        push!(wishes, guest_ids)
    end
    wishes = [getindex(guest_names, guest_id) for guest_id in wishes]
    return wishes
end

function make_wishes(guests_file, wishes_file, mwm=8, mwf=8)
    guests = HappyScheduler.get_guests(guests_file)
    Fwishes = get_random_wishes(filter(x -> x.gender == :F, guests), mwf)
    Mwishes = get_random_wishes(filter(x -> x.gender == :M, guests), mwm)
    open(wishes_file, "w") do io
        writedlm(io, Fwishes, "; ")
        writedlm(io, Mwishes, "; ")
    end
    lines = readlines(wishes_file)
    open(wishes_file, "w") do io
        for line in lines
            write(io, randstring(8)*"@"*randstring(4)*".com; "*line*"\n")
        end
    end
    return nothing
end

make_wishes(
    joinpath(@__DIR__, "data","guests1000.csv"),
    joinpath(@__DIR__, "data", "wishes1000.csv"),
)
