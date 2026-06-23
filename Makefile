UNAME := $(shell uname)

ifeq ($(UNAME), Darwin)
  DYLIB_EXT  := dylib
  DYLIB_FLAG := -dynamiclib
else
  DYLIB_EXT  := so
  DYLIB_FLAG := -shared -fPIC
endif

TARGET := libkaappi_sqlite.$(DYLIB_EXT)

all: $(TARGET)

$(TARGET): csrc/kaappi_sqlite.c
	$(CC) $(DYLIB_FLAG) -o $@ $< -lsqlite3 -O2 -Wall -Wextra

clean:
	rm -f $(TARGET)

.PHONY: all clean
