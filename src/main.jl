using DataStructures
include("Singletons.jl")


s = """S -> aSb \n S -> aAb \n A -> cAc \n A -> c \n  S -> c"""

c = getCFG(s)

@show aut = buildPositionDFA(c)



@show p = buildPDA(aut, c)

str = InputString("aaaaacccccbbbbb")


u = parsePDA(str, p)