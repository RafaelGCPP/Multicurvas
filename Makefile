
CC = gcc
CFLAGS = -Wall -Wextra -std=c99 -I./include
LDFLAGS = -L$(BUILDDIR) -lmulticurvas -lm


SRCDIR = src
BUILDDIR = build
TESTDIR = test
LIBNAME = libmulticurvas.a
LIBPATH = $(BUILDDIR)/$(LIBNAME)


SOURCES = $(wildcard $(SRCDIR)/*.c)
OBJECTS = $(patsubst $(SRCDIR)/%.c, $(BUILDDIR)/%.o, $(SOURCES))
TEST_SOURCES = $(wildcard $(TESTDIR)/*.c)
TEST_BINS = $(patsubst $(TESTDIR)/%.c, $(BUILDDIR)/%.test, $(TEST_SOURCES))
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

all: library tests run-tests

library: $(LIBPATH) $(MEMTEST_TARGET)

$(LIBPATH): $(OBJECTS)
	ar rcs $@ $^


$(BUILDDIR)/%.test: $(TESTDIR)/%.c $(LIBPATH) | $(BUILDDIR)
	$(CC) $(CFLAGS) $< -o $@ $(LDFLAGS)

$(BUILDDIR)/%.o: $(SRCDIR)/%.c | $(BUILDDIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILDDIR):
	mkdir -p $(BUILDDIR)

clean:
	rm -rf $(BUILDDIR)

# Target para compilar todos os testes
tests: $(TEST_BINS)

# Target para rodar todos os testes
run-tests: tests
	@for t in $(TEST_BINS); do echo "Executando $$t:"; $$t; done

.PHONY: all clean help tests run-tests



help:
	@echo "Targets disponíveis:"
	@echo "  all         - Compila a biblioteca, os testes e executa todos os binários de teste."
	@echo "  library     - Compila apenas a biblioteca estática (.a)."
	@echo "  tests       - Compila um executável para cada arquivo .c em test/."
	@echo "  run-tests   - Executa todos os binários de teste."
	@echo "  clean       - Remove arquivos gerados e diretório build."
	@echo "  help        - Mostra esta mensagem de ajuda."
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
