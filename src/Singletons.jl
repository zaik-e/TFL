

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

include("CFG.jl")
include("DFA.jl")
include("PDA.jl")
include("PositionRule.jl")