import Base: ==

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

==(first::PositionRule, second::PositionRule) = equalPosRules(first, second)