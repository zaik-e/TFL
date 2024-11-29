
struct CFG{TΣ, TN}
    Σ::Set{TΣ}
    N::Set{TN}
    Rules::Set{Tuple{TN, AbstractVector{Union{TΣ, TN}}}}
    Start::TN
end

function CFG(
    Σ::Set{TΣ},
    N::Set{TN},
    Rules::Set{Tuple{TN, AbstractVector}},
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
    Rules::Set{Tuple},
    Start::TN
    ) where {TΣ, TN}
    Σ = Set{Union{TΣ, Epsilon}}(Σ)
    N = Set{TN}(N)
    ϵ ∉ Σ && push!(Σ, ϵ)
    Rules = Set{Tuple{TN, AbstractVector{Union{TΣ, TN, Epsilon}}}}(Rules)
    CFG{Union{TΣ, Epsilon}, TN}(Σ, N, Rules, Start)    
end

function addPrestartRule(g::CFG, rule::Tuple{TN, AbstractVector}) where {TN}
    Σ = g.Σ
    N = g.N
    push!(N, rule[1])
    Rules = g.Rules
    push!(Rules, rule)
    Start = rule[1]

    CFG(Σ, N, Rules, Start)    
end


function getCFG(input)
    Term = Set()
    NTerm = Set()
    AllSymb = Set()
    Rules = Set{Tuple}()
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
        push!(Rules, (leftnterm, right))
    end
    Term = setdiff(AllSymb, NTerm)

    return CFG(Term, NTerm, Rules, Start)
end
