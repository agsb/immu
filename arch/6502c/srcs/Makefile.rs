
# Final output filename
BINFILE = editor.prg
CFGFILE = src/editor.cfg

obj/%.o: src/%.asm
    ca65 $< -g -o $@ -I src

clean:
   - mkdir -p obj
   - mkdir -p bin
   - rm -f obj/*
   - rm -f bin/*

all: clean obj/editor.o
    ld65 -Ln L -C $(CFGFILE) -m obj/map -o bin/$(BINFILE) $^
    @sed '1,/^$/ d' obj/map | sed -n '/Exports list/q;p
