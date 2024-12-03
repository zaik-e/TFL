using DataStructures
include("Singletons.jl")


s = """S -> SSa \n S -> SbS \n S -> a"""

c = getCFG(s)

aut = buildPositionDFA(c)
for i ∈ aut.Q 
    f = i.number
    r = "$f  "
    for j ∈ i.Rules
        a = j.Rule
        b= j.curposition
        r *= " $a $b "
    end
    println(r)
end


function reverseTransWithoutSymb(dfa::DFA)
    result = Dict{Any, Set}()
    for (from, to) ∈ dfa.δ
        fromstate = from[1]
        if !(haskey(result, to))
            result[to] = Set()
        end
        push!(result[to], fromstate)
    end
    result    
end

function findReduces(state::PositionState)
    result = Set()
    for posrule ∈ state.Rules
        if posrule.curposition == posrule.maxposition
            push!(result, (posrule.Rule[1], posrule.maxposition))
        end
    end
    result
end

function makeSteps(reversed_trans::Dict, countsteps::Int, startstate)
    curstates = Set([startstate])
    while countsteps > 0
        newstates = Set()
        for state ∈ curstates
            union!(newstates, reversed_trans[state])
        end
        curstates = newstates
        countsteps -= 1        
    end
    curstates    
end



function buildPDA(pdfa::DFA, cfg::CFG)
    Q = pdfa.Q
    Σ = cfg.Σ
    Γ = Set()
    δ = Dict{Tuple, eltype(Q)}()
    q₀ = pdfa.q0
    F = pdfa.F

    reduce_from = Dict()  #стомтояния + нетерм и куда переход
    δ_pdfa_reversed = reverseTransWithoutSymb(pdfa)

    for (from, to) ∈ pdfa.δ
        if from[2] ∈ Σ
            δ[(from[1], from[2], ∀, [Zi(to.number), ∀])] = to
            push!(Γ, Zi(to.number))
        end
    end

    for state ∈ Q 
        reduces = findReduces(state)
        if (isempty(reduces))
            continue
        end
        for (nterm, len) ∈ reduces
            stepsback_states = makeSteps(δ_pdfa_reversed, len, state)
            for nextstate ∈ stepsback_states
                if haskey(pdfa.δ, (nextstate, nterm))
                    reduce_from[(state, len, nextstate)] = pdfa.δ[(nextstate, nterm)]
                end
            end
        end
    end

    for (key, val) ∈ reduce_from
        start_state = key[1]
        numberofsteps = key[2]
        redusefrom_state = key[3]
        destin_state = val
        # while numberofsteps > 0
        #     new_state = PositionState(inccounter())
        #     push!(Q, new_state)
        #     δ[(start_state, ϵ, ∀, [ϵ])] = new_state
        #     start_state = new_state
        #     numberofsteps -= 1            
        # end
        adding = Vector{Union{UniversalSymb, Zi}}([∀ for _=1:numberofsteps+1])
        adding[1] = Zi(redusefrom_state.number)
        δ[(start_state, ϵ, adding,
            [Zi(destin_state.number), Zi(redusefrom_state.number)])] = destin_state

    end

    PDA(Q, Σ, Γ, δ, q₀, F)
end

p = buildPDA(aut, c)

str = InputString("a")




# function parsePDA(input::InputString, automata::PDA)
#     configuration = configPDA(automata.q₀, [Z₀], input)

#     function parsing(config::configPDA)
#         if !isempty(config.restofword)
#             configs = []
#             for (from, to) ∈ automata.δ
#                 fromstate = from[1]
#                 symb = from[2]
#                 fromstack = from[3]
#                 tostack = from[4]
#                 if (fromstate == config.currentstate)
#                     if fromstack <: AbstractArray

#                     elseif fromstack == config.stack[end]
#                         ((symb == config.restofword[1]) && 
#                         (push!(configs, configPDA(to, config.stack))))
#         else 
#             (config.currentstate ∈ automata.F)
#     end
#     while !isempty(configuration.restofword)
        
#     end

# end
