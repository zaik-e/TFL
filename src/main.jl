include("definitions.jl")


s = """S -> A0a0b\n  a0 ->  cc \nA0 -> c \n S -> A0 A0 \n \n"""
@show c = getCFG(s)
