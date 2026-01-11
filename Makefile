CC = gcc
CFLAGS = -Wall -Wextra -std=c99 -I./include -lm
SRCDIR = src
BUILDDIR = build
TARGET = $(BUILDDIR)/multicurvas

SOURCES = $(wildcard $(SRCDIR)/*.c)
OBJECTS = $(patsubst $(SRCDIR)/%.c, $(BUILDDIR)/%.o, $(SOURCES))


all: $(TARGET)


$(TARGET): $(OBJECTS)
	$(CC) $^ -o $@ $(CFLAGS)


$(BUILDDIR)/%.o: $(SRCDIR)/%.c | $(BUILDDIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILDDIR):
	mkdir -p $(BUILDDIR)


clean:
	rm -rf $(BUILDDIR) $(TARGET)

run: $(TARGET)
	./$(TARGET)

.PHONY: all clean run
