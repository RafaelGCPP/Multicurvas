CC = gcc
CFLAGS = -Wall -Wextra -std=c99 -I./include -lm -O3
SRCDIR = src
BUILDDIR = build
TARGET = $(BUILDDIR)/multicurvas
BENCHMARK_TARGET = $(BUILDDIR)/benchmark
MEMTEST_TARGET = $(BUILDDIR)/memory_test

# Arquivos comuns (excluindo os mains)
COMMON_SOURCES = $(SRCDIR)/parser.c $(SRCDIR)/evaluator.c $(SRCDIR)/debug.c
COMMON_OBJECTS = $(patsubst $(SRCDIR)/%.c, $(BUILDDIR)/%.o, $(COMMON_SOURCES))

# Objetos específicos dos executáveis
MAIN_OBJECTS = $(BUILDDIR)/main.o
BENCHMARK_OBJECTS = $(BUILDDIR)/main_benchmark.o $(BUILDDIR)/benchmark.o
MEMTEST_OBJECTS = $(BUILDDIR)/memory_test.o

all: $(TARGET) $(BENCHMARK_TARGET) $(MEMTEST_TARGET)

$(TARGET): $(COMMON_OBJECTS) $(MAIN_OBJECTS)
	$(CC) $^ -o $@ $(CFLAGS)

$(BENCHMARK_TARGET): $(COMMON_OBJECTS) $(BENCHMARK_OBJECTS)
	$(CC) $^ -o $@ $(CFLAGS)

$(MEMTEST_TARGET): $(COMMON_OBJECTS) $(MEMTEST_OBJECTS)
	$(CC) $^ -o $@ $(CFLAGS)

$(BUILDDIR)/%.o: $(SRCDIR)/%.c
	$(CC) $(CFLAGS) -c $< -o $@ $(MEMTEST_TARGET)

run: $(TARGET)
	./$(TARGET)

benchmark: $(BENCHMARK_TARGET)
	./$(BENCHMARK_TARGET)

memtest: $(MEMTEST_TARGET)
	./$(MEMTEST_TARGET)

.PHONY: all clean run benchmark memtest
	./$(BENCHMARK_TARGET)

.PHONY: all clean run benchmark
