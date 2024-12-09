"""
Inspired by Tixy05
"""

struct DFA{T, S}
    Q::Set{T}                             
    Σ::Set{S}                             
    δ::Dict{Tuple{T, S}, T}               
    q0::T                                 
    F::Set{T}                            
end

function DFA(
        Q::Set{T},
        Σ::Set{S},
        δ::Dict{Tuple{T, S}, T},
        q0::T,
        F::Set{T},
    ) where {T, S}
    Q = Set{Union{T, Trap}}(Q)
    F = Set{Union{T, Trap}}(F)
    δ = Dict{Tuple{Union{T, Trap}, S}, Union{T, Trap}}(δ)
     
    DFA{Union{T, Trap}, S}(Q, Σ, δ, q0, F)
end

function DFA(
    Q::Set{Union{T, Trap}},
    Σ::Set{S},
    δ::Dict{Tuple{Union{T, Trap}, S}, Union{T, Trap}},
    q0::Union{T, Trap},
    F::Set{Union{T, Trap}},
) where {T, S}
    DFA{Union{T, Trap}, S}(Q, Σ, δ, q0, F)
end


function Base.show(io::IO, automaton::DFA)
    delete_quotas(ω) = replace("$ω", "\"" => "")
    res = """"""
    for q ∈ automaton.Q
        strq = q.number
        if q ∈ automaton.F
            res *= "\"$strq\" [shape=doublecircle]"
        else
            res *= "\"$strq\" [shape=circle]"
        end
        res *= "\n"
    end

    res *= "start [shape=point]\n"
    strq0 = automaton.q0.number
    res *= "start -> \"$strq0\"\n"
    for ((start_state, letter), end_state) ∈ automaton.δ
        strstart = start_state.number
        strend = end_state.number
        res *= "\"$strstart\" -> \"$strend\" [label=\"$letter\"]\n"
    end
    res = "digraph Automaton {\n" * res * "}\n"
    print(io, res)
end
