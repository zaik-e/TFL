using DataStructures

abstract type State end  

struct PositionState <: State
    Rules::Set{PositionRule}
    number::Int 
end

function PositionState(num::Int)
    Rules = Set{PositionRule}()
    number = num
    PositionState(Rules, number)    
end

function addRule(state::PositionState, rule::PositionRule)
    rules = push!(state.Rules, rule)
    # num = state.number + 1
    PositionState(rules, state.number)
end

function addRulesForNTerm!(state::PositionState, cfg::CFG, nterm)
    for (left, right) ∈ cfg.Rules
        if left == nterm
            state = addRule(state, PositionRule((left, right)))
        end
    end
    state
end

function addRulesFromTrans!(childstate::PositionState, parentstate::PositionState, symb, cfg::CFG)
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


Base.hash(a::PositionState, h::UInt) = hash(a.Rules, hash(:PositionState, h))
Base.isequal(a::PositionState, b::PositionState) = Base.isequal(hash(a), hash(b))


function buildPositionDFA(cfg::CFG)
    prestartRule = PositionRule(("(Zero)", [cfg.Start]))
    grammar = addPrestartRule(cfg, ("(Zero)", [cfg.Start]))

    Q = Set{PositionState}()
    Σ = setdiff(union(grammar.Σ, grammar.N), Set([ϵ]))
    δ = Dict{Tuple{PositionState, eltype(Σ)}, PositionState}()
    F = Set{PositionState}()

    countstates = 0

    queue = Queue{PositionState}()
    veryfirststate = PositionState(inccounter())
    veryfirststate = addRule(veryfirststate, prestartRule)
    addRulesForNTerm!(veryfirststate, grammar, cfg.Start)
    enqueue!(queue, veryfirststate)
    push!(Q, veryfirststate)

    while (!isempty(queue))
        currentstate = first(queue)
        dequeue!(queue)
        
        for symb ∈ Σ
            nextstate = PositionState(getcounter())
            addRulesFromTrans!(nextstate, currentstate, symb, grammar)
            if isempty(nextstate.Rules) 
                continue
            end
            if !(nextstate ∈ Q) 
                push!(Q, nextstate)
                enqueue!(queue, nextstate)
                δ[(currentstate, symb)] = nextstate
                inccounter()

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
