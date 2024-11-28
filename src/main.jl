include("Singletons.jl")
import Base: ==
using DataStructures


s = """S -> A0a0b\n  a0 ->  cc \nA0 -> c \n S -> A0 A0 \n \n"""

@show c = getCFG(s)

struct PositionRule{TΣ, TN}
    Rule::Tuple{TN, AbstractVector{Union{TΣ, TN}}}
    maxposition::Int
    curposition::Int
end

function PositionRule(
    rule::Tuple{TN, AbstractVector{Union{TΣ, TN}}},
    cpos::Int,
    mpos::Int
    ) where {TΣ, TN}
    maxposition = mpos
    curposition = cpos
    Rule = rule
    PositionRule{TΣ, TN}(Rule, maxposition, curposition)    
end


function PositionRule(
    rule::Tuple{TN, AbstractVector{Union{TΣ, TN}}}
    ) where {TΣ, TN}
    maxposition = size(rule[2])[1]
    curposition = 0
    Rule = rule
    PositionRule{TΣ, TN}(Rule, maxposition, curposition)    
end



function buildPositionDFA(grammar::CFG)
    Q = Set{PositionRule}()
    Σ = union(grammar.Σ, grammar.N)
    δ = Dict()
    F = Set{PositionRule}()
    prestartRule = PositionRule(("(Zero)", [grammar.Start]))
    q₀ = prestartRule    
end

function equalPosRules(first::PositionRule, second::PositionRule)
    return ((first.maxposition == second.maxposition) && (first.curposition == second.curposition) &&
        deepcopy(first.Rule) == deepcopy(second.Rule))
    
end


==(first::PositionRule, second::PositionRule) = equalPosRules(first, second)



Q = Set([1, 2, 3, 4])
Σ = Set(['a', 'b', ϵ])
δ = Dict{Tuple{Int, Union{Any}}, Int}()
F = Set([2])

push!(δ, (1, 'a') => 2)
push!(δ, (2, 'b') => 3)
push!(δ, (2, 'b') => 4)
push!(δ, (2, 'a') => 1)
push!(δ, (3, ϵ) => 1)
