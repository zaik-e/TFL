struct PDA{T, S, M}
    Q::Set{T}
    Σ::Set{S}
    Γ::Set{M}
    δ::Dict{Tuple{T, S, M, AbstractVector{M}}, T}
    q₀::T
    F::Set{T}
end

function PDA(
        Q::Set{T},
        Σ::Set{S},
        Γ::Set{M},
        δ::Dict{Tuple, T},
        q₀::T,
        F::Set{T},
    ) where {T, S, M}
    Q = Set{Union{T, Trap}}(Q)
    Γ = Set{Union{M, Z0, Epsilon}}(Γ)
    Σ = Set{Union{S, Epsilon}}(Σ)
    F = Set{Union{T, Trap}}(F)
    δ = Dict{Tuple{Union{T, Trap}, Union{S, Epsilon}, Union{M, Z0, Epsilon},
            AbstractVector{Union{M, Z0, Epsilon}}}, Union{T, Trap}}(δ)
    Z₀ ∉ Γ && push!(Γ, Z₀)
    ϵ ∉ Γ && push!(Γ, ϵ)
    ϵ ∉ Σ && push!(Σ, ϵ)
    PDA{Union{T, Trap},  Union{S, Epsilon}, Union{M, Z0, Epsilon}}(Q, Σ, Γ, δ, q₀, F)
end

function PDA(
    Q::Set{Union{T, Trap}},
    Σ::Set{Union{S, Epsilon}},
    Γ::Set{Union{M, Z0, Epsilon}},
    δ::Dict{Tuple{Union{T, Trap}, Union{S, Epsilon}, Union{M, Z0, Epsilon},
            AbstractVector{Union{M, Z0, Epsilon}}}, Union{T, Trap}},
    q₀::Union{T, Trap},
    F::Set{Union{T, Trap}},
) where {T, S, M}
    PDA{Union{T, Trap}, Union{S, Epsilon}, Union{M, Z0, Epsilon}}(Q, Σ, Γ, δ, q₀, F)
end


function Base.show(io::IO, automaton::PDA)
    delete_quotas(ω) = replace("$ω", "\"" => "")
    res = """"""
    for q ∈ automaton.Q
        strq = delete_quotas(q)
        if q ∈ automaton.F
            res *= "\"$strq\" [shape=doublecircle]"
        else
            res *= "\"$strq\" [shape=circle]"
        end
        res *= "\n"
    end

    res *= "start [shape=point]\n"
    strq0 = delete_quotas(automaton.q₀)
    res *= "start -> \"$strq0\"\n"
    for ((start_state, letter, pop, push), end_state) ∈ automaton.δ
        strstart = delete_quotas(start_state)
        strend = delete_quotas(end_state)
        pushstr = ""
        for el ∈ push
            pushstr *= String(el)
        end
        res *= "\"$strstart\" -> \"$strend\" [label=\"$letter, $pop / $pushstr\"]\n"
    end
    res = "digraph PDA {\n" * res * "}\n"
    print(io, res)
end
