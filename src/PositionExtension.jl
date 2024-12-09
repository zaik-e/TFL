using DataStructures

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
    rule::Tuple{TN, AbstractVector{Union{TΣ, TN}}},
    curpos::Int
    ) where {TΣ, TN}
    maxposition = size(rule[2])[1]
    curposition = curpos
    Rule = rule
    PositionRule{TΣ, TN}(Rule, maxposition, curposition)    
end

function PositionRule(
    rule::Tuple{TN, AbstractVector{TA}}
    ) where {TA, TN}
    maxposition = size(rule[2])[1]
    curposition = 0
    Rule = rule
    PositionRule{TA, TN}(Rule, maxposition, curposition)    
end


function equalPosRules(first::PositionRule, second::PositionRule)
    return ((first.maxposition == second.maxposition) && (first.curposition == second.curposition) &&
        deepcopy(first.Rule) == deepcopy(second.Rule))
    
end

Base.:(==)(first::PositionRule, second::PositionRule) = equalPosRules(first, second)


struct PositionState
    Rules::Set{PositionRule}
    number::Int
end

function PositionState(num::Int)
    Rules = Set{PositionRule}()
    PositionState(Rules, num)    
end

function addRule(state::PositionState, rule::PositionRule)
    rules = push!(state.Rules, rule)
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
