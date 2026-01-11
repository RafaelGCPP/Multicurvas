CC = gcc
CFLAGS = -Wall -Wextra -std=c99 -I./include -lm -O3
SRCDIR = src
BUILDDIR = build
TARGET = $(BUILDDIR)/multicurvas
BENCHMARK_TARGET = $(BUILDDIR)/benchmark

# Arquivos comuns (excluindo os mains)
COMMON_SOURCES = $(SRCDIR)/parser.c $(SRCDIR)/evaluator.c $(SRCDIR)/debug.c
COMMON_OBJECTS = $(patsubst $(SRCDIR)/%.c, $(BUILDDIR)/%.o, $(COMMON_SOURCES))

# Objetos específicos dos executáveis
MAIN_OBJECTS = $(BUILDDIR)/main.o
BENCHMARK_OBJECTS = $(BUILDDIR)/main_benchmark.o $(BUILDDIR)/benchmark.o

all: $(TARGET) $(BENCHMARK_TARGET)

$(TARGET): $(COMMON_OBJECTS) $(MAIN_OBJECTS)
	$(CC) $^ -o $@ $(CFLAGS)

$(BENCHMARK_TARGET): $(COMMON_OBJECTS) $(BENCHMARK_OBJECTS)
	$(CC) $^ -o $@ $(CFLAGS)

$(BUILDDIR)/%.o: $(SRCDIR)/%.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -rf $(BUILDDIR)/*.o $(TARGET) $(BENCHMARK_TARGET)

run: $(TARGET)
	./$(TARGET)

benchmark: $(BENCHMARK_TARGET)
	./$(BENCHMARK_TARGET)

.PHONY: all clean run benchmark
