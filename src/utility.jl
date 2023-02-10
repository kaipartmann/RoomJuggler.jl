
function get_nonempty_cols(m::Matrix{T}) where {T<:AbstractString}
    n_rows, _ = size(m)
    nonempty_cols = Vector{Int}()
    for (i, col) in enumerate(eachcol(m))
        if !(sum(isempty.(col)) == n_rows)
            push!(nonempty_cols, i)
        end
    end

    return m[:, nonempty_cols]
end

function get_nonempty_rows(m::Matrix{T})  where {T<:AbstractString}
    _, n_cols = size(m)
    nonempty_rows = Vector{Int}()
    for (i, row) in enumerate(eachrow(m))
        if !(sum(isempty.(row)) == n_cols)
            push!(nonempty_rows, i)
        end
    end

    return m[nonempty_rows, :]
end

function nonempty(m::Matrix{T})  where {T<:AbstractString}
    return m |> get_nonempty_cols |> get_nonempty_rows
end

nonempty(v::Vector{T}) where {T<:AbstractString} = v[findall(x -> !isempty(x), v)]
