
#define CC_TARGET

SOURCES = main.s

PROGRAM = main

ifdef CC65_TARGET
CC      = cl65
CFLAGS  = -t $(CC65_TARGET) --create-dep $(<:.c=.d) -O
LDFLAGS = -t $(CC65_TARGET) -m $(PROGRAM).map
else
CC      = gcc
CFLAGS  = -MMD -MP -O
LDFLAGS = -Wl,-Map,$(PROGRAM).map
endif

########################################

.SUFFIXES:
.PHONY: all clean
all: $(PROGRAM)

ifneq ($(MAKECMDGOALS),clean)
-include $(SOURCES:.c=.d)
endif

%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $<

$(PROGRAM): $(SOURCES:.c=.o)
	$(CC) $(LDFLAGS) -o $@ $^

clean:
	$(RM) $(SOURCES:.c=.o) $(SOURCES:.c=.d) $(PROGRAM) $(PROGRAM).map

