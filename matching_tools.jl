#=
Tools for matching algorithms.

Author: Daisuke Oyama

=#

# random_prefs

"""
    random_prefs([rng, ]m, n, allow_unmatched=true)

Generate random preference order lists for two groups, say, m males and n
females.

Each male has a preference order over femals [1, ..., n] and "unmatched" which
is represented by 0, while each female has a preference order over males
[1, ..., m] and "unmatched" which is again represented by 0.

The optional `rng` argument specifies a random number generator.

# Arguments

- `m::Integer` : Number of males.
- `n::Integer` : Number of females.
- `allow_unmatched::Bool(true)` : If false, return preference order lists of
males and females where 0 is always placed in the last place, (i.e.,
"unmatched" is least preferred by every individual).

# Returns

- `m_prefs::Matrix{Int}` :  Array of shape (n+1, m), where each column contains
a random permutation of 0, 1, ..., n.
- `f_prefs::Matrix{Int}` :  Array of shape (m+1, n), where each column contains
a random permutation of 0, 1, ..., m.

# Examples

```julia
julia> m_prefs, f_prefs = random_prefs(4, 3);

julia> m_prefs
4x4 Array{Int64,2}:
 3  3  1  3
 0  2  3  1
 2  1  2  0
 1  0  0  2

julia> f_prefs
5x3 Array{Int64,2}:
 1  2  4
 4  3  1
 3  4  2
 0  0  0
 2  1  3

julia> m_prefs, f_prefs = random_prefs(4, 3, allow_unmatched=false);

julia> m_prefs
4x4 Array{Int64,2}:
 1  3  1  2
 2  1  3  3
 3  2  2  1
 0  0  0  0

julia> f_prefs
5x3 Array{Int64,2}:
 1  2  3
 2  3  4
 4  1  1
 3  4  2
 0  0  0
```
"""
function random_prefs(rng::AbstractRNG,
	                  m::Integer, n::Integer; allow_unmatched::Bool=true)
    m_prefs = _random_prefs(rng, m, n, allow_unmatched)
    f_prefs = _random_prefs(rng, n, m, allow_unmatched)
    return m_prefs, f_prefs
end

random_prefs(m::Integer, n::Integer; allow_unmatched::Bool=true) =
    random_prefs(Base.GLOBAL_RNG, m, n, allow_unmatched=allow_unmatched)


function _random_prefs(r::AbstractRNG,
	                   m::Integer, n::Integer, allow_unmatched::Bool)
    prefs = Array(Int, n+1, m)
    for j in 1:m
        prefs[end, j] = 0
    end

    _randperm2d!(r, sub(prefs, 1:n, :))

    if allow_unmatched
        unmatched_rankings = rand(r, 2:n+1, m)
        for j in 1:m
            prefs[end, j] = prefs[unmatched_rankings[j], j]
            prefs[unmatched_rankings[j], j] = 0
        end
    end

    return prefs
end


# Copied from base/random.jl
"Return a random `Int` (masked with `mask`) in ``[0, n)``, when `n <= 2^52`."
@inline function rand_lt(r::AbstractRNG, n::Int, mask::Int=nextpow2(n)-1)
    # this duplicates the functionality of RangeGenerator objects,
    # to optimize this special case
    while true
        x = (Base.Random.rand_ui52_raw(r) % Int) & mask
        x < n && return x
    end
end

# In-place version of randperm in base/random.jl
"""
Given a vector `a` of length n, generate a random permutation of length n and
store it in `a`.
"""
function _randperm!{T<:Integer}(r::AbstractRNG, a::AbstractVector{T})
    # a = Array{typeof(n)}(n)
    n = length(a)
    @assert n <= Int64(2)^52
    if n == 0
       return a
    end
    a[1] = 1
    mask = 3
    @inbounds for i = 2:Int(n)
        j = 1 + rand_lt(r, i, mask)
        if i != j # a[i] is uninitialized (and could be #undef)
            a[i] = a[j]
        end
        a[j] = i
        i == 1+mask && (mask = 2mask + 1)
    end
    return a
end


"""
Given an m x n matrix `a`, generate n random permutations of length m and store
them in columns of `a`.
"""
function _randperm2d!{T<:Integer}(r::AbstractRNG, a::AbstractMatrix{T})
    m, n = size(a)
    for j in :1:n
        _randperm!(r, sub(a, :, j))
    end
    a
end
