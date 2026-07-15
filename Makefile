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

# abaco_test.c é o helper do test-runner da lib Abaco (não é uma suíte em si)
ABACO_TEST_HELPER_OBJ = $(BUILDDIR)/abaco_test.o
ABACO_TEST_SOURCES = $(filter-out $(ABACO_TESTDIR)/abaco_test.c, $(wildcard $(ABACO_TESTDIR)/*.c))

# Testes (do app e da lib Abaco)
TEST_SOURCES = $(wildcard $(TESTDIR)/*.c) $(ABACO_TEST_SOURCES)
TEST_BINS = $(patsubst $(TESTDIR)/%.c, $(BUILDDIR)/%.test, $(wildcard $(TESTDIR)/*.c)) \
            $(patsubst $(ABACO_TESTDIR)/%.c, $(BUILDDIR)/%.test, $(ABACO_TEST_SOURCES))

all: $(MAIN_BIN) tests

# Compila executável principal
$(MAIN_BIN): $(BUILDDIR)/main.o $(CORE_OBJECTS) | $(BUILDDIR)
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS)

# Compila testes do app
$(BUILDDIR)/%.test: $(TESTDIR)/%.c $(CORE_OBJECTS) | $(BUILDDIR)
	$(CC) $(CFLAGS) $< $(CORE_OBJECTS) -o $@ $(LDFLAGS)

# Compila testes da lib Abaco (linkando o helper abaco_test.o)
$(BUILDDIR)/%.test: $(ABACO_TESTDIR)/%.c $(CORE_OBJECTS) $(ABACO_TEST_HELPER_OBJ) | $(BUILDDIR)
	$(CC) $(CFLAGS) $< $(CORE_OBJECTS) $(ABACO_TEST_HELPER_OBJ) -o $@ $(LDFLAGS)

$(ABACO_TEST_HELPER_OBJ): $(ABACO_TESTDIR)/abaco_test.c $(ABACO_TESTDIR)/abaco_test.h | $(BUILDDIR)
	$(CC) $(CFLAGS) -c $< -o $@

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
	@status=0; \
	for t in $(TEST_BINS); do \
		echo "Executando $$t:"; \
		$$t || status=1; \
	done; \
	exit $$status

# Atualiza o submodule lib/abaco para o commit mais recente do remote,
# revalida com os testes, mas NÃO commita/dá push — isso fica por sua conta
# depois de revisar o que mudou.
update-abaco:
	@echo "--- Buscando último commit de lib/abaco no remote ---"
	git submodule update --remote lib/abaco
	@echo ""
	@echo "--- Diff do submodule (commits novos) ---"
	@git diff --submodule=log -- lib/abaco
	@echo ""
	@$(MAKE) clean
	@$(MAKE) run-tests
	@echo ""
	@echo "lib/abaco atualizado e testado. Se estiver tudo certo:"
	@echo "  git add lib/abaco && git commit -m 'Atualiza submodule Abaco' && git push"

help:
	@echo "Targets disponíveis:"
	@echo "  all           - Compila o executável principal e testes"
	@echo "  tests         - Compila testes (app + lib Abaco)"
	@echo "  run-tests     - Executa todos os testes"
	@echo "  update-abaco  - Atualiza o submodule lib/abaco pro último commit e testa"
	@echo "  clean         - Remove arquivos compilados"
	@echo ""
	@echo "Executável: $(MAIN_BIN)"
	@echo "Uso: ./build/multicurvas \"Y=sin(x)\" svg > sin.svg"

.PHONY: all tests run-tests update-abaco clean help
