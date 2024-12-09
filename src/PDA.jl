struct PDA{T, S, M}
    Q::Set{T}
    Σ::Set{S}
    Γ::Set{M}
    δ::Dict{Tuple{T, S, M, AbstractVector{M}}, T}
    q₀::T
    F::Set{T}
end

struct configPDA{T, S, M}
    currentstate::T
    stack::Vector{M}
    restofword::Vector{S}
end

function configPDA(
    currentstate::T,
    stack::Vector{M},
    restofword::InputString
    ) where {T, M}
    configPDA(currentstate, stack, restofword.data)    
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
    Γ = Set{Union{M, Zi, Epsilon}}(Γ)
    Σ = Set{Union{S, Epsilon}}(Σ)
    F = Set{Union{T, Trap}}(F)
    δ = Dict{Tuple{Union{T, Trap}, Union{S, Epsilon}, Union{M, Zi, Epsilon, UniversalSymb},
            AbstractVector{Union{M, Zi, Epsilon, UniversalSymb}}}, Union{T, Trap}}(δ)
    Z₀ ∉ Γ && push!(Γ, Z₀)
    ϵ ∉ Γ && push!(Γ, ϵ)
    ϵ ∉ Σ && push!(Σ, ϵ)
    ∀ ∉ Γ && push!(Γ, ∀)
    PDA{Union{T, Trap},  Union{S, Epsilon}, Union{M, Zi, Epsilon, UniversalSymb}}(Q, Σ, Γ, δ, q₀, F)
end

function PDA(
    Q::Set{Union{T, Trap}},
    Σ::Set{Union{S, Epsilon}},
    Γ::Set{Union{M, Zi, Epsilon, UniversalSymb}},
    δ::Dict{Tuple{Union{T, Trap}, Union{S, Epsilon}, Union{M, Zi, Epsilon, UniversalSymb},
            AbstractVector{Union{M, Zi, Epsilon, UniversalSymb}}}, Union{T, Trap}},
    q₀::Union{T, Trap},
    F::Set{Union{T, Trap}},
) where {T, S, M}
    PDA{Union{T, Trap}, Union{S, Epsilon}, Union{M, Zi, Epsilon, UniversalSymb}}(Q, Σ, Γ, δ, q₀, F)
end


function Base.write(io::IO, automaton::PDA)
    delete_quotas(ω) = replace("$ω", "\"" => "")
    res = """"""
    for q ∈ automaton.Q
        strq = q.number
        if q ∈ automaton.F
            res *= "\"$strq\" [shape=doublecircle]"
        else
            res *= "\"$strq\" [shape=circle]"
        end
        res *= "\n"
    end

    res *= "start [shape=point]\n"
    strq0 = automaton.q₀.number
    res *= "start -> \"$strq0\"\n"
    for ((start_state, letter, pop, push), end_state) ∈ automaton.δ
        strstart = start_state.number
        strend = end_state.number
        pushstr = ""
        popstr = ""
        for el ∈ push
            pushstr *= String(el)
        end
        if typeof(pop) <: AbstractArray    
            for el ∈ pop
                popstr *= String(el)
            end
        else
            popstr = "$pop"
        end
        res *= "\"$strstart\" -> \"$strend\" [label=\"$letter, $popstr / $pushstr\"]\n"
    end
    res = "digraph PDA {\n" * res * "}\n"
    write(io, res)
end


function savePDA(path_to_file::String, pda::PDA)
    open(path_to_file, "w") do file
        serialize(file, pda)
    end
end

function loadPDA(path_to_file::String)
    open(path_to_file, "r") do file
        deserialize(file)
    end
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


# Внимание: вершина стека справа, т.е. в последнем элементе вектора
function buildPDA(pdfa::DFA, cfg::CFG)
    Q = pdfa.Q
    Σ = cfg.Σ
    Γ = Set()
    δ = Dict{Tuple, eltype(Q)}()
    q₀ = pdfa.q0
    F = pdfa.F

    reduce_from = Dict()  #состояния + нетерм + переход
    δ_pdfa_reversed = reverseTransWithoutSymb(pdfa)

    for (from, to) ∈ pdfa.δ
        if from[2] ∈ Σ
            δ[(from[1], from[2], ∀, [ ∀, Zi(to.number)])] = to
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

        adding = Vector{Union{UniversalSymb, Zi}}([∀ for _=1:numberofsteps+1])
        adding[1] = Zi(redusefrom_state.number)
        δ[(start_state, ϵ, adding,
            [Zi(redusefrom_state.number), Zi(destin_state.number)])] = destin_state

    end

    PDA(Q, Σ, Γ, δ, q₀, F)
end


function parsePDA(input::InputString, automata::PDA)
    configuration = configPDA(automata.q₀, [Z₀], input)
    
    function parsing(config::configPDA)
        # println(config.currentstate.number, " ", config.restofword, " ", config.stack)
        if !isempty(config.restofword)
            configs = []
            for (from, to) ∈ automata.δ
                fromstate = from[1]
                symb = from[2]
                fromstack = from[3]
                tostack = from[4]
                
                if (fromstate == config.currentstate)
                    if ((typeof(fromstack) <: AbstractArray) && (length(fromstack) <= length(config.stack) &&
                        config.stack[end - length(fromstack) + 1] == fromstack[1]))
                
                        if (symb == ϵ)
                            push!(configs, 
                                  configPDA(to, [config.stack[1:end - length(fromstack) + 1]; tostack[2:end]], 
                                  config.restofword[1:end]))
                    
                        elseif symb == config.restofword[1]
                            push!(configs, configPDA(to, [config.stack[1:end - length(fromstack) + 1]; tostack[2:end]], config.restofword[2:end]))
                        end 
                        
                    elseif (fromstack == config.stack[end])
                        if (symb == ϵ)
                            push!(configs, configPDA(to, [config.stack[1:end]; tostack[2:end]], config.restofword[1:end]))
                            
                        elseif symb == config.restofword[1]
                            push!(configs, configPDA(to, [config.stack[1:end]; tostack[2:end]], config.restofword[2:end])) 
                        end
                    end
                end
            end
            return any(map(parsing, configs))

        else
            if config.currentstate ∈ automata.F
                return true
            end

            configs = []
            for (from, to) ∈ automata.δ
                fromstate = from[1]
                symb = from[2]
                fromstack = from[3]
                tostack = from[4]
                if (fromstate == config.currentstate) && (symb == ϵ)
                    if ((typeof(fromstack) <: AbstractArray) && (length(fromstack) <= length(config.stack) &&
                        config.stack[end - length(fromstack) + 1] == fromstack[1]))
                        push!(configs, configPDA(to, [config.stack[1:end - length(fromstack) + 1]; tostack[2:end]], config.restofword[1:end]))
                                                
                    elseif (fromstack == config.stack[end])
                        push!(configs, configPDA(to, [config.stack[1:end]; tostack[2:end]], config.restofword[1:end]))   
                    end 
                end
            end
            return ((length(configs) > 0) && any(map(parsing, configs)))
        end
    end
    
    return parsing(configuration)
end
