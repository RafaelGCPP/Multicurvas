CC = gcc
CFLAGS = -Wall -Wextra -std=c99 -I./include
LDFLAGS = -lm

SRCDIR = src
BUILDDIR = build
TESTDIR = test

# Arquivos core (sem main.c)
CORE_SOURCES = $(filter-out $(SRCDIR)/main.c, $(wildcard $(SRCDIR)/*.c))
CORE_OBJECTS = $(patsubst $(SRCDIR)/%.c, $(BUILDDIR)/%.o, $(CORE_SOURCES))

# Executável principal
MAIN_BIN = $(BUILDDIR)/multicurvas

# Testes
TEST_SOURCES = $(wildcard $(TESTDIR)/*.c)
TEST_BINS = $(patsubst $(TESTDIR)/%.c, $(BUILDDIR)/%.test, $(TEST_SOURCES))

all: $(MAIN_BIN) tests

# Compila executável principal
$(MAIN_BIN): $(BUILDDIR)/main.o $(CORE_OBJECTS) | $(BUILDDIR)
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS)

# Compila testes
$(BUILDDIR)/%.test: $(TESTDIR)/%.c $(CORE_OBJECTS) | $(BUILDDIR)
	$(CC) $(CFLAGS) $< $(CORE_OBJECTS) -o $@ $(LDFLAGS)

$(BUILDDIR)/%.o: $(SRCDIR)/%.c | $(BUILDDIR)
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
	@echo "  tests       - Compila testes"
	@echo "  run-tests   - Executa todos os testes"
	@echo "  clean       - Remove arquivos compilados"
	@echo ""
	@echo "Executável: $(MAIN_BIN)"
	@echo "Uso: ./build/multicurvas \"Y=sin(x)\" svg > sin.svg"

.PHONY: all tests run-tests clean help
	@echo "  run-tests   - Executa todos os binários de teste."
	@echo "  clean       - Remove arquivos gerados e diretório build."
	@echo "  help        - Mostra esta mensagem de ajuda."

.PHONY: all clean help tests run-tests library
