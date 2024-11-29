
struct DFA{T, S}
    Q::Set{T}                             # States
    Σ::Set{S}                             # Alphabet
    δ::Dict{Tuple{T, S}, T}               # Transition function
    q0::T                                 # Initital state
    F::Set{T}                             # Final states
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

function get_neighbors(α::DFA, q)
    Set((α.δ[q, c], c) for c ∈ α.Σ)
end

Base.:!(A::DFA) = DFA(
        copy(A.Q),
        copy(A.Σ),
        copy(A.δ),
        A.q0,
        setdiff(A.Q, A.F),
    )

"""
For now function is very crappy in such a way that only
'kinda similar' looking automata could be intersected, i.e. A1 and A2 are
required to be parametrized with identical types and A1.Σ must equals A2.Σ
"""
function Base.:∩(A1::DFA{T, S}, A2::DFA{T, S}) where {T, S}
    A1.Σ ≠ A2.Σ && @error "Automata alphabets are not equal"

    Q = Set{Union{Tuple{T, T}, Trap}}(Iterators.product(A1.Q, A2.Q))
    replace!(Q, (TRAP, TRAP) => TRAP)

    Σ = A1.Σ

    #  δ(⟨q1,q2⟩,c)=⟨δ1(q1,c),δ2(q2,c)⟩
    δ = Dict{Tuple{Union{Tuple{T, T}, Trap}, S}, Union{Tuple{T, T}, Trap}}() 
    for q1 ∈ A1.Q, q2 ∈ A2.Q, c ∈ Σ
        old = ((q1, q2), c)
        if old[1] == (TRAP, TRAP) old = (TRAP, c) end 
        new = (A1.δ[q1, c], A2.δ[q2, c])
        if new == (TRAP, TRAP) new = TRAP end  
        δ[old] = new
    end

    q0 = (A1.q0, A2.q0)
    F = Set{Union{Tuple{T, T}, Trap}}(Iterators.product(A1.F, A2.F))
    replace!(Q, (TRAP, TRAP) => TRAP)
    DFA(Q, Σ, δ, q0, F)
end


"""
Note that visualizing big .dot file (over couple hundred vertices/states) may 
result in a very long processing time. Also, even if graph is planar in theory, 
it may be not rendered as one.  
"""
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


# @show aut = buildPositionDFA(c)
# for i ∈ aut.Q 
#     f = i.number
#     r = "$f  "
#     for j ∈ i.Rules
#         a = j.Rule
#         b= j.curposition
#         r *= " $a $b "
#     end
#     println(r)
# end
