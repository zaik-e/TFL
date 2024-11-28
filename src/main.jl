include("definitions.jl")


t = Vector(['a', 'l'])
@show typeof(t)

Q = Set([1, 2, 3])
Σ = Set("abc")
Γ = Set("ABC")
F = Set([2])
δ = Dict{Tuple, Int}()
δ[Tuple([1, 'a', ϵ, Vector([ϵ])])] = 2
δ[Tuple([1, 'a', ϵ, Vector(['A', 'B'])])] = 3

pda = PDA(Q, Σ, Γ, δ, 1, F)

Rules = Set{Dict{Char, AbstractVector}}()
push!(Rules, Dict(['A' => Vector(['A', 'a'])]))
push!(Rules, Dict(['A' => Vector(['a', 'b'])]))

cfg = CFG(Σ, Γ, Rules, 'A')
