
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
    TRAP ∉ Q && push!(Q, TRAP)
    for q ∈ Q, c ∈ Σ
        _ = get!(δ, (q, c)) do 
            TRAP
        end
    end
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
    res = """rankdir="LR"\n"""
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
    strq0 = delete_quotas(automaton.q0)
    res *= "start -> \"$strq0\"\n"
    for ((start_state, letter), end_state) ∈ automaton.δ
        strstart = delete_quotas(start_state)
        strend = delete_quotas(end_state)
        res *= "\"$strstart\" -> \"$strend\" [label=\"$letter\"]\n"
    end
    res = "digraph Automaton {\n" * res * "}\n"
    print(io, res)
end

"""
Dumb implementation of the Hopcroft minimization algorithm.
Runs at O(|Σ||E|log|E|) time.
Copied from Wikipedia.
"""
function equivalence_classes(α::DFA)
    P = Set()
    W = Set()
    push!(P, α.F, setdiff(α.Q, α.F))
    push!(W, α.F, setdiff(α.Q, α.F))

    while !isempty(W)
        A = rand(W)
        delete!(W, A)
        for c ∈ α.Σ
            X = Set()
            for q ∈ α.Q
                !haskey(α.δ, (q, c)) && continue
                α.δ[q, c] ∈ A && push!(X, q)
            end
            for Y ∈ P
                (isempty(X ∩ Y) || isempty(setdiff(Y, X))) &&
                    continue
                delete!(P, Y)
                push!(P, X ∩ Y, setdiff(Y, X))
                if Y ∈ W
                    delete!(W, Y)
                    push!(W, X ∩ Y, setdiff(Y, X))
                else
                    length(X ∩ Y) <= length(setdiff(Y, X)) ?
                        push!(W, X ∩ Y) :
                        push!(W, setdiff(Y, X))
                end
            end
        end
    end

    P
end

function minimize(α::DFA{T, S})::DFA where {T, S}
    classes = [equivalence_classes(α)...]
    state_to_class = Dict()
    for (index, class) ∈ enumerate(classes), state ∈ class
        state_to_class[state] = index
    end

    new_Q = Set{Int}(eachindex(classes))
    new_Σ = α.Σ
    new_δ = Dict{Tuple{Int, S}, Int}()
    new_F = Set{Int}()
    new_q0 = state_to_class[α.q0]
    for (index, class) ∈ enumerate(classes), c ∈ α.Σ
        q = rand(class)
        q ∈ α.F && push!(new_F, index)
        new_δ[index, c] = state_to_class[α.δ[q, c]]
    end

    DFA(new_Q, new_Σ, new_δ, new_q0, new_F)
end

"""
visualize works works only on Unix-like systems.
"""
function visualize(automaton, filepath_wo_ext)
    Sys.isunix() || @error "works only on Unix-like systems :(" 
    io_buffer = IOBuffer() 
    show(io_buffer, automaton)    
    graph = String(take!(io_buffer))
    cmd = pipeline(`echo $graph`,  `dot -Tsvg`)
    open("$filepath_wo_ext.svg", "w") do io
        run(pipeline(cmd, stdout=io))
    end
end

"""
Builds DFA from equivalence table
"""
function DFA_from_table(
        main_prefixes, 
        complementary_prefixes, 
        rows,
    )
    # FIXME wtf is going on with epsilons
    state_map = Dict(p => idx for (idx, p) ∈ enumerate(main_prefixes))
    prefix_to_row = Dict()
    all_prefixes = map(String, vcat(main_prefixes, complementary_prefixes))
    # ????? "ϵ" ≠ "ϵ"
    eps = all_prefixes[1]
    for (row, p) ∈ zip(rows, all_prefixes)
        prefix_to_row[p] = row
    end
    row_to_prefix = Dict()
    for (row, p) ∈ zip(rows, main_prefixes)
        row_to_prefix[row] = p
    end
    Q = Set{Int}(1:length(main_prefixes))
    q0 = 0
    Σ = Set{Char}(['L', 'R'])
    δ = Dict{Tuple{Int, Char}, Int}()
    F = Set{Int}()

    for (p, row) ∈ zip(main_prefixes, rows)
        row[1] == 1 && push!(F, state_map[p])
    end
    # ????? "ϵ" ≠ "ϵ"
    for p ∈ all_prefixes
        if p == eps
            q0 = state_map[p]
            continue
        end
        sub_prefix = p[1:length(p)-1]
        if sub_prefix == ""
            sub_prefix = eps
        end
        letter = p[length(p)]
        from = state_map[row_to_prefix[prefix_to_row[sub_prefix]]]
        to = state_map[row_to_prefix[prefix_to_row[p]]]
        δ[from, letter] = to
    end
    DFA(Q, Σ, δ, q0, F)
end
