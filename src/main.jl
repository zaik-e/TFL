include("Singletons.jl")
using DataStructures


s = """S -> aA\n  A ->  bS \nS -> c"""

@show c = getCFG(s)

struct PositionalState
    Rules::Set{PositionRule}
    number::Int 
end

function PositionalState(num::Int)
    Rules = Set{PositionRule}()
    number = num
    PositionalState(Rules, number)    
end

function addRule(state::PositionalState, rule::PositionRule)
    rules = push!(state.Rules, rule)
    # num = state.number + 1
    PositionalState(rules, state.number)
end

function addRulesForNTerm!(state::PositionalState, cfg::CFG, nterm)
    for (left, right) ∈ cfg.Rules
        if left == nterm
            state = addRule(state, PositionRule((left, right)))
        end
    end
    state
end

function addRulesFromTrans!(childstate::PositionalState, parentstate::PositionalState, symb, cfg::CFG)
    for rule ∈ parentstate.Rules
        if ((rule.curposition < rule.maxposition) &&
            (rule.Rule[2][rule.curposition + 1] == symb))
            childstate = addRule(childstate, PositionRule(rule.Rule, rule.curposition + 1))
            if (rule.curposition + 2 <= rule.maxposition)
                addRulesForNTerm!(childstate, cfg, rule.Rule[2][rule.curposition + 2])
            end
        end
    end
    childstate
end

function buildPositionDFA(grammar::CFG)
    Q = Set{PositionalState}()
    Σ = setdiff(union(grammar.Σ, grammar.N), Set([ϵ]))
    δ = Dict{Tuple{PositionalState, eltype(Σ)}, PositionalState}()
    F = Set{PositionalState}()
    prestartRule = PositionRule(("(Zero)", [grammar.Start]))
    q₀ = prestartRule

    countstates = 0

    queue = Queue{PositionalState}()
    veryfirststate = PositionalState(countstates)
    countstates += 1
    veryfirststate = addRule(veryfirststate, prestartRule)
    addRulesForNTerm!(veryfirststate, grammar, q₀)
    enqueue!(queue, veryfirststate)

    while (!isempty(queue))
        currentstate = first(queue)
        dequeue!(queue)
        
        for symb ∈ Σ
            println(symb)
            nextstate = PositionalState(countstates)
            countstates += 1
            addRulesFromTrans!(nextstate, currentstate, symb, grammar)
            if isempty(nextstate.Rules) 
                continue
            end
            if !(nextstate ∈ Q) 
                push!(Q, nextstate)
                enqueue!(queue, nextstate)
            end
            δ[(currentstate, symb)] = nextstate
        end
    end

    DFA(Q, Σ, δ, veryfirststate, F)
end

@show aut = buildPositionDFA(c)
