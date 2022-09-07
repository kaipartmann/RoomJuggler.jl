using DelimitedFiles

function generate_random_rooms(n_guests; max_room_size=8)
    n_rooms = floor(Int, n_guests / max_room_size)
    capacities = length.(defaultdist(n_guests, n_rooms))
    names = ["room $i" for i in 1:n_rooms]
    genders = [rand([:M, :F]) for _ in 1:n_rooms]
    open(joinpath(@__DIR__, "data", string("rooms",n_guests,".csv")), "w") do io
        writedlm(io, [["name" "capacity" "gender"]; [names capacities genders]], "; ")
    end
end

"""
    defaultdist(sz::Int, nc::Int)

Get array of indices for dividing sz into nc chunks.
"""
function defaultdist(sz::Int, nc::Int)
    if sz >= nc
        chunk_size = div(sz, nc)
        remainder = rem(sz, nc)
        sidx = zeros(Int64, nc + 1)
        for i in 1:(nc + 1)
            sidx[i] += (i - 1) * chunk_size + 1
            if i <= remainder
                sidx[i] += i - 1
            else
                sidx[i] += remainder
            end
        end
        grid = fill(0:0, nc)
        for i in 1:nc
            grid[i] = sidx[i]:(sidx[i + 1] - 1)
        end
        return grid
    else
        sidx = [1:(sz + 1);]
        grid = fill(0:0, nc)
        for i in 1:sz
            grid[i] = sidx[i]:(sidx[i + 1] - 1)
        end
        return grid
    end
end

generate_random_rooms(1050)
