struct Trap end
const TRAP = Trap()
Base.String(_::Trap) = "TRAP"
Base.show(io::IO, _::Trap) = print(io, "TRAP")

struct Z0 end
const Z₀ = Z0()
Base.String(_::Z0) = "Z₀"
Base.show(io::IO, _::Z0) = print(io, "Z₀")

struct Epsilon end
const ϵ = Epsilon()
Base.String(_::Epsilon) = "ϵ"
Base.show(io::IO, _::Epsilon) = print(io, "ϵ")

# TODO add support for epsilon stuff in Alphabet

### считаем что в хнф?
struct CFG{TΣ, TN}
    Σ::Set{TΣ}
    N::Set{TN}
    Rules::Set{Dict{TN, AbstractVector{Union{TΣ, TN}}}}
    Start::TN
end

function CFG(
    Σ::Set{TΣ},
    N::Set{TN},
    Rules::Set{Dict{TN, AbstractVector}},
    Start::TN
    ) where {TΣ, TN}
    Σ = Set{Union{TΣ, Epsilon}}(Σ)
    N = Set{TN}(N)
    ϵ ∉ Σ && push!(Σ, ϵ)
    Rules = Set{Dict{TN, AbstractVector{Union{TΣ, TN, Epsilon}}}}(Rules)
    CFG{Union{TΣ, Epsilon}, TN}(Σ, N, Rules, Start)    
end


function CFG(
    Σ::Set{TΣ},
    N::Set{TN},
    Rules::Set{Dict},
    Start::TN
    ) where {TΣ, TN}
    Σ = Set{Union{TΣ, Epsilon}}(Σ)
    N = Set{TN}(N)
    ϵ ∉ Σ && push!(Σ, ϵ)
    Rules = Set{Dict{TN, AbstractVector{Union{TΣ, TN, Epsilon}}}}(Rules)
    CFG{Union{TΣ, Epsilon}, TN}(Σ, N, Rules, Start)    
end



struct PDA{T, S, M}
    Q::Set{T}                             # States
    Σ::Set{S}
    Γ::Set{M}                             # Alphabet
    δ::Dict{Tuple{T, S, M, AbstractVector{M}}, T}               # Transition function
    q₀::T                              # Initital state
    F::Set{T}                             # Final states
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


function getCFG(input)
    Term = Set()
    NTerm = Set()
    AllSymb = Set()
    Rules = Set{Dict}()
    Start = ""

    for line ∈ split(input, '\n')
        if (strip(line, ' ') == "")
            continue
        end
        splited = split(strip(line, ' '), ' ')
        
        leftnterm = splited[1]
        right = []
        push!(NTerm, leftnterm)
        isempty(Start) && (Start = leftnterm) 

        for part ∈ splited[3:end]
            if (part== "")
                continue
            end
            currsymb = ""
            for symb in part
                if (currsymb == "")
                    if ('a' <= symb <= 'z')
                        currsymb *= string(symb)
                    elseif ('A' <= symb <= 'Z')
                        currsymb *= string(symb)
                    end
                else 
                    if ('0' <= symb <= '9')
                        currsymb *= string(symb)
                    elseif ('a' <= symb <= 'z') || ('A' <= symb <= 'Z')
                        push!(AllSymb, currsymb)
                        push!(right, currsymb)
                        currsymb = string(symb)
                    end
                end
            end
            push!(AllSymb, currsymb)
            push!(right, currsymb)
        end
        push!(Rules, Dict(leftnterm => right))
    end
    Term = setdiff(AllSymb, NTerm)

    return CFG(Term, NTerm, Rules, Start)
end
