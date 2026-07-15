CC = gcc
CFLAGS = -Wall -Wextra -std=c99 -I./include -I./lib/abaco/include
LDFLAGS = -lm

SRCDIR = src
BUILDDIR = build
TESTDIR = test

# Biblioteca Abaco (parser/avaliador de expressões), vendorizada em lib/abaco/
ABACO_SRCDIR = lib/abaco/src
ABACO_TESTDIR = lib/abaco/tests

# Arquivos core (sem main.c), incluindo os da lib Abaco
APP_CORE_SOURCES = $(filter-out $(SRCDIR)/main.c, $(wildcard $(SRCDIR)/*.c))
ABACO_SOURCES = $(wildcard $(ABACO_SRCDIR)/*.c)
CORE_SOURCES = $(APP_CORE_SOURCES) $(ABACO_SOURCES)
CORE_OBJECTS = $(patsubst $(SRCDIR)/%.c, $(BUILDDIR)/%.o, $(APP_CORE_SOURCES)) \
               $(patsubst $(ABACO_SRCDIR)/%.c, $(BUILDDIR)/%.o, $(ABACO_SOURCES))

# Executável principal
MAIN_BIN = $(BUILDDIR)/multicurvas

# Testes (do app e da lib Abaco)
TEST_SOURCES = $(wildcard $(TESTDIR)/*.c) $(wildcard $(ABACO_TESTDIR)/*.c)
TEST_BINS = $(patsubst $(TESTDIR)/%.c, $(BUILDDIR)/%.test, $(wildcard $(TESTDIR)/*.c)) \
            $(patsubst $(ABACO_TESTDIR)/%.c, $(BUILDDIR)/%.test, $(wildcard $(ABACO_TESTDIR)/*.c))

all: $(MAIN_BIN) tests

# Compila executável principal
$(MAIN_BIN): $(BUILDDIR)/main.o $(CORE_OBJECTS) | $(BUILDDIR)
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS)

# Compila testes do app
$(BUILDDIR)/%.test: $(TESTDIR)/%.c $(CORE_OBJECTS) | $(BUILDDIR)
	$(CC) $(CFLAGS) $< $(CORE_OBJECTS) -o $@ $(LDFLAGS)

# Compila testes da lib Abaco
$(BUILDDIR)/%.test: $(ABACO_TESTDIR)/%.c $(CORE_OBJECTS) | $(BUILDDIR)
	$(CC) $(CFLAGS) $< $(CORE_OBJECTS) -o $@ $(LDFLAGS)

$(BUILDDIR)/%.o: $(SRCDIR)/%.c | $(BUILDDIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILDDIR)/%.o: $(ABACO_SRCDIR)/%.c | $(BUILDDIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILDDIR):
	mkdir -p $(BUILDDIR)

clean:
	rm -rf $(BUILDDIR)

tests: $(TEST_BINS)

run-tests: tests
	@for t in $(TEST_BINS); do echo "Executando $$t:"; $$t; done

help:
	@echo "Targets disponíveis:"
	@echo "  all         - Compila o executável principal e testes"
	@echo "  tests       - Compila testes (app + lib Abaco)"
	@echo "  run-tests   - Executa todos os testes"
	@echo "  clean       - Remove arquivos compilados"
	@echo ""
	@echo "Executável: $(MAIN_BIN)"
	@echo "Uso: ./build/multicurvas \"Y=sin(x)\" svg > sin.svg"

.PHONY: all tests run-tests clean help
