I_j := -Ilibs/build
L_j := -Llibs/build
l_j := -ljga
Wl_j := -Wl,-rpath libs/build
I_x := -Iexternal/build
L_x := -Lexternal/build
l_x := -lexternal
Wl_x := -Wl,-rpath external/build
l := $(l_j) $(l_x) -lglfw -ldl
l_cxx := $(so_libs)cxx $(so_external) -lglfw -ldl
Wl_rpath := -Wl,-rpath external/build -Wl,-rpath libs/build
D := -D_DEBUG -DEXPORT

CFLAGS := -g -Wall $(I_j)
CXXFLAGS := $(CFLAGS)
LDFLAGS := $(L_j) $(l_j) $(Wl_j)
LDXXFLAGS := $(LDFLAGS)

SRC_C := $(shell find src -type f -regextype posix-extended -regex '.*\.c' -and -not -regex '.*/test\.c')
SRC_CXX := $(shell find src -type f -regextype posix-extended -regex '.*\.cpp' -and -not -regex '.*/test\.cpp')
SRC_ASM := $(shell find src -type f -regextype posix-extended -regex '.*\.c' -and -not -regex '.*/test\.asm')
SRC_TEX := $(notdir $(shell find -maxdepth 1 -type f -name "*.tex"))

.PHONY: compile_commands.json all run runc runasm clean echo

all: build_external build_libs $(patsubst src/%,build/%.out,$(SRC_C) $(SRC_CXX) $(SRC_ASM))

build_external:
	$(MAKE) -C external

build_libs:
	$(MAKE) -C libs


build/pdf/%.pdf: %.tex
	@mkdir -p $(shell sed -En 's#src/(.*/)*.+#build/pdf/\1#p' <<< $<)
	pdflatex --jobname=$(patsubst %.tex,build/pdf/%, $<) $<

pdf :$(patsubst %.tex,build/pdf/%.pdf, $(SRC_TEX))

runpdf :$(patsubst %.tex,build/pdf/%.pdf, $(SRC_TEX))
	@nohup zathura $(word 1, $^) &

build/obj/%.asm.o: src/%.asm
	@mkdir -p $(shell sed -En 's#src/(.*/)*.+#build/obj/\1#p' <<< $<)
	nasm -felf64 -o$@ $<
build/%.asm.out: build/obj/%.asm.o
	gcc $(LDFLAGS) -o $@ $<

runasm: $(patsubst src/%,build/%.out,$(SRC_ASM))
	./build/main.asm.out


build/%.c.out: src/%.c
	@mkdir -p $(shell sed -En 's#src/(.*/)*.+#build/\1#p' <<< $<)
	gcc $(CFLAGS) $(LDFLAGS) -o $@ $<

runc: $(patsubst src/%,build/%.out,$(SRC_C))
	./build/main.c.out

build/%.cpp.out: src/%.cpp 
	@mkdir -p $(shell sed -En 's#src/(.*/)*.+#build/\1#p' <<< $<)
	g++ -std=c++20 $(CXXFLAGS) $(LDXXFLAGS) -o $@ $< 

run: $(patsubst src/%,build/%.out,$(SRC_CXX))
	./build/main.cpp.out


tmp := $(shell find -type f,l -regextype posix-extended -regex '(./compile_commands.json$$)|(./build/.*)|(./(app|src|libs|test)/.*\.(hi|o|so|out|aux|log|toc|nav|snm|lot|lof)$$)' -and -not -regex '.*(\.git|pack|dist.*)/.*')
echo:
	$(MAKE) -C external echo
	$(MAKE) -C libs echo
	echo "This is Geometric Algbra Root dir!" #$(tmp)
clean:
	$(MAKE) -C libs clean
	rm $(tmp)


build/json/%.cpp.json: src/%.cpp
	@mkdir -p $(shell sed -En 's#src/(.*/)*.+#build/json/\1#p' <<< $<)
	clang++ -MJ $@ -std=c++20  $(CXXFLAGS) $(LDXXFLAGS) -o/dev/null $<

build/json/%.c.json: src/%.c
	@mkdir -p $(shell sed -En 's#src/(.*/)*.+#build/json/\1#p' <<< $<)
	clang -MJ $@ $(CFLAGS) $(LDFLAGS) -o/dev/null $<

compile_commands.json:  $(patsubst src/%,build/json/%.json,$(SRC_C)) $(patsubst src/%,build/json/%.json,$(SRC_CXX))
	$(shell sed -E -e '1s#^#[\n#' -e '$$s#,$$#\n]#' `find build -type f -regextype posix-extended -regex ".*/.*\.json" -and -not -regex ".*/.*\.compile_commands.json"` > compile_commands.json)

