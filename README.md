# ЛР 3: Построение PDA по CFG
*Вариант: PDA на основе LR(0)*

### Необходимые зависимости 
```
pkg> add DataStructures
pkg> add Serialization
```

### Запуск
```
julia src/main.jl
```

Поддерживаются аргументы командной строки в качестве режимов запуска:
```
-l [path/filename.jls = saved/pda1.jls]    load pda from file
-s [path/filename.jls = saved/pda1.jls]    save pda to file 
-t [path/filename.ext = tests/test1.txt]   testing
```
Режимы `-l` и `-s` не могут быть запущены одновременно: в режиме загрузки из файла тестируется уже построенный PDA, в режиме сохранения происходит генерация PDA по КС-грамматике и его тестирование.

Ключи могут идти в произвольном порядке. 
После аргумента-ключа опционально возможно указать конкретный файл, использующийся соответственно режиму; имена файлов по умолчанию (при наличии конкретного ключа) указаны выше. 
При отсутствии аргументов ключ `-s` включен , т.е. 
`julia src/main.jl`   =   `julia src/main.jl -s` .

Отсутствие ключа `-t` означает режим интерактивного тестирования - ввод проверяемых строк из консоли. Его включение означает использование тестов из текстового файла (в формате, указанном в условии лабораторной).

Например,
```
julia src/main.jl -l -t tests/mytest.txt
```
означает, что автомат загрузится из файла `saved/pda1.jls` и пройдет тесты из `tests/mytest.txt`.

### Ввод
... заканчивается при появлении пустой строки.

### Ограничения и формат входных данных
... соответствуют условию л.р. (корректная обработка правил с пустой правой частью не гарантируется).

### Визуализация автомата
При вводе грамматики генерируется также dot-файл, отражающий построенный PDA. При наличии Graphviz можно сгенерировать изображение автомата, например, так:

```
dot saved/pda1.dot -Tsvg > pda1.svg
```
**Внимание!**
1. В обозначениях последовательностей стековых символов вершина стека находится *справа*.
2. Добавлены сокращения для цепочек переходов: несколько эпсилон-переходов, снимающих символы со стека, обозначаются как один переход.

<img align="left" width="200" src="readme_img/image_chain.png"> <img align="left" width="200" src="readme_img/image_short.png">

Здесь, например, переход в состояние 4 осуществляется, если на стеке третьим символом оказался Z₀, при этом он остается в стеке и добавляется Z₄ (стековые символы, ранее находившиеся над Z₀, снимаются).
