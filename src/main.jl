include("Singletons.jl")
using DataStructures


s = """S -> aSb \nS -> c"""

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


Base.hash(a::PositionalState, h::UInt) = hash(a.Rules, hash(:PositionalState, h))
Base.isequal(a::PositionalState, b::PositionalState) = Base.isequal(hash(a), hash(b))


function buildPositionDFA(cfg::CFG)
    prestartRule = PositionRule(("(Zero)", [cfg.Start]))
    grammar = addPrestartRule(cfg, ("(Zero)", [cfg.Start]))

    Q = Set{PositionalState}()
    Σ = setdiff(union(grammar.Σ, grammar.N), Set([ϵ]))
    δ = Dict{Tuple{PositionalState, eltype(Σ)}, PositionalState}()
    F = Set{PositionalState}()

    countstates = 0

    queue = Queue{PositionalState}()
    veryfirststate = PositionalState(countstates)
    countstates += 1
    veryfirststate = addRule(veryfirststate, prestartRule)
    addRulesForNTerm!(veryfirststate, grammar, cfg.Start)
    enqueue!(queue, veryfirststate)
    push!(Q, veryfirststate)

    while (!isempty(queue))
        currentstate = first(queue)
        dequeue!(queue)
        
        for symb ∈ Σ
            nextstate = PositionalState(countstates)
            addRulesFromTrans!(nextstate, currentstate, symb, grammar)
            if isempty(nextstate.Rules) 
                continue
            end
            if !(nextstate ∈ Q) 
                push!(Q, nextstate)
                enqueue!(queue, nextstate)
                δ[(currentstate, symb)] = nextstate
                countstates += 1

                if (currentstate.number == 0) && (symb == cfg.Start)
                    push!(F, nextstate)
                end

            else
                existed = collect(setdiff(Q, setdiff(Q, Set([nextstate]))))[1]
                δ[(currentstate, symb)] = existed
            end
            
        end
    end

    DFA(Q, Σ, δ, veryfirststate, F)
end

