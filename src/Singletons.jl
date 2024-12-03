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

struct UniversalSymb end
const ∀ = UniversalSymb()
Base.String(_::UniversalSymb) = "∀"
Base.show(io::IO, _::UniversalSymb) = print(io, "∀")

struct Zi 
    i::Int
end

function subscriptnumber(i::Int)
    if i < 0
        c = [Char(0x208B)]
    else
        c = []
    end
    for d in reverse(digits(abs(i)))
        push!(c, Char(0x2080+d))
    end
    return join(c)
end

function tostr(s::Zi)
    number = s.i
    return "Z"*subscriptnumber(number)
end

Base.String(e::Zi) = tostr(e)
Base.show(io::IO, e::Zi) = print(io, tostr(e))


global StateCounter = 0

function scounter() 
    function increment() 
        global StateCounter += 1
        return StateCounter-1
    end
    function get()
        return StateCounter
    end
    return increment, get 
end 

inccounter, getcounter = scounter()


struct InputString
    data::Vector
end

function Base.getindex(input::InputString, i::Int)
    return input.data[i]    
end

function Base.length(input::InputString)
    return length(input.data)
end

function InputString(input::AbstractString)
    InputString((map(string, collect(input))))
end

include("CFG.jl")
include("DFA.jl")
include("PDA.jl")
include("PositionRule.jl")
include("PositionState.jl")