using DataStructures
using Serialization
include("Singletons.jl")



"""
-l load from file
-s save to file 
-t testing
по умолчанию включен -s и интерактивное тестирование
"""

function main()
    path_to_save = ""
    path_to_load = ""
    path_to_test = ""

    save_load = 0
    if isempty(ARGS)
        path_to_save = "saved/pda1.jls"
        save_load = 1
    else
        index = 1
        while index <= length(ARGS)
            arg = ARGS[index]
            if arg == "-s"
                if save_load == 2
                    println("Указан режим загрузки из файла. Попробуйте другие аргументы.")
                    return
                end
                if (index < length(ARGS) && ARGS[index+1][1] != '-')
                    path_to_save = ARGS[index+1]
                    if path_to_save[end-3:end] != ".jls"
                        println("Укажите файл c расширением jls.")
                        return
                    end
                    index += 2
                else
                    path_to_save = "saved/pda1.jls"
                    index += 1
                end
                save_load = 1
            elseif arg == "-l"
                if save_load == 1
                    println("Указан режим сохранения. Попробуйте другие аргументы.")
                    return
                end
                if (index < length(ARGS) && ARGS[index+1][1] != '-')
                    path_to_load = ARGS[index+1]
                    if path_to_load[end-3:end] != ".jls"
                        println("Укажите файл c расширением jls")
                        return
                    end
                    index += 2
                else
                    path_to_load = "saved/pda1.jls"
                    index += 1
                end
                save_load = 2
            elseif arg == "-t"
                if (index < length(ARGS) && ARGS[index+1][1] != '-')
                    path_to_test = ARGS[index+1]
                    index += 2
                else
                    path_to_test = "tests/test1.txt"
                    index += 1
                end
            else
                println("Неверный тип аргументов. Попробуйте еще раз.")
                return
            end
        end
    end

    if save_load == 0
        path_to_save = "saved/pda1.jls"
        save_load = 1
    end

    if save_load == 1
        println("КС-грамматика:")
        grammar_str = ""
        while true
            line = readline()
            if line == "0"
                break
            end
            grammar_str = grammar_str * line * "\n"
        end
        cfg = getCFG(grammar_str)
        posDFA = buildPositionDFA(cfg)
        pda = buildPDA(posDFA, cfg)

        savePDA(path_to_save, pda)

    else
        pda = loadPDA(path_to_load)
    end

    if path_to_test == ""
        println("Строки для тестирования:")
        while true
            line = readline()
            if line == "0"
                break
            end
            str = InputString(strip(line, ' '))
            println(parsePDA(str, pda))
        end
    else
        println("Здесь будет режим тестирования")
    end
        

end

main()

# s = """S -> aSb \n S -> aAb \n \n A -> cAc \n A -> c \n  S -> c"""

# c = getCFG(s)

# aut = buildPositionDFA(c)

# p = buildPDA(aut, c)

# savePDA("saved/pda1.jls", p)

# p2 = loadPDA("saved/pda1.jls")


# str = InputString("aaaaacccccbbbbb")


# u = parsePDA(str, p2)
# println(u)