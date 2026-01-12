# Multicurvas - Documentação Técnica

## Visão Geral do Projeto

**Objetivo**: Criar um parser e avaliador de expressões matemáticas (função de uma variável) que seja modular e educativo, recriando funcionalmente o programa de plotagem de gráficos do ZX81 em C moderno com RPN (Reverse Polish Notation).

**Fases planejadas**:
1. ✅ Tokenização + Validação
2. ✅ Conversão para RPN (Shunting Yard) - [Ver algoritmo detalhado](SHUNTING_YARD.md)
3. ✅ Avaliador de RPN
4. ✅ Otimizações de Performance (pilha estática, Token compacto)
5. ✅ Benchmark de Performance
6. ✅ Sistema de Plotagem (CSV e SVG)

---

## Módulos

### `tokens.h` / `tokens.c` (Conceitual)

**Responsabilidade**: Definir os tipos de tokens e constantes que representam elementos da linguagem matemática.

**Por que modular**: Permite que parser, debug e avaliador usem as mesmas definições de tokens, evitando duplicação e facilitando extensão futura.

#### Tipos Customizados

##### `enum LocaleConfig`
```c
typedef enum {
    LOCALE_POINT,      /* 3.14 (padrão C/EN) */
    LOCALE_COMMA       /* 3,14 (PT-BR, FR, DE) */
} LocaleConfig;
```
- **Finalidade**: Configurar a marca decimal aceita pelo parser
- **Valores**: `LOCALE_POINT` ou `LOCALE_COMMA`
- **Uso**: Passar para `parser_set_locale()`
- **Padrão**: `LOCALE_POINT`

##### `enum TokenType`
```c
typedef enum {
  /* Operadores (ASCII) */
  TOKEN_PLUS       = '+',
  TOKEN_MINUS      = '-',
  TOKEN_MULT       = '*',
  TOKEN_DIV        = '/',
  TOKEN_POW        = '^',
  TOKEN_LPAREN     = '(',
  TOKEN_RPAREN     = ')',

  /* Literais e especiais a partir de 128 */
  TOKEN_NUMBER     = 128,

  /* Variáveis: range 129-138 (10 slots) */
  TOKEN_VARIABLE_X = 129,
  TOKEN_VARIABLE_THETA = 130,
  TOKEN_VARIABLE_T = 131,

  /* Constantes: range 140-159 (20 slots) */
  TOKEN_CONST_PI   = 140,
  TOKEN_CONST_E    = 141,

  /* Funções: range 160-199 (40 slots) */
  TOKEN_SIN        = 160,
  TOKEN_COS        = 161,
  TOKEN_TAN        = 162,
  TOKEN_ABS        = 163,
  TOKEN_SQRT       = 164,
  TOKEN_EXP        = 165,
  TOKEN_LOG        = 166,
  TOKEN_LOG10      = 167,
  TOKEN_SINH       = 168,
  TOKEN_COSH       = 169,
  TOKEN_TANH       = 170,
  TOKEN_ASIN       = 171,
  TOKEN_ACOS       = 172,
  TOKEN_ATAN       = 173,
  TOKEN_ASINH      = 174,
  TOKEN_ACOSH      = 175,
  TOKEN_ATANH      = 176,
  TOKEN_CEIL       = 177,
  TOKEN_FLOOR      = 178,
  TOKEN_FRAC       = 179,
  TOKEN_NEG        = 180,

  TOKEN_END        = 255,  /* Fim da expressão */
  TOKEN_ERROR      = 254   /* Erro de parsing (reservado) */
} TokenType;
```

- **Estratégia de encoding**:
  - Operadores básicos usam valores ASCII (permite cast direto: `(char)token`)
  - Especiais >= 128 para identificar "bytecodes" da linguagem
  - **Sistema de ranges**: Variáveis (129-138), Constantes (140-159), Funções (160-199)
  - Permite extensibilidade sem modificar funções auxiliares
   (Otimizado)
```c
typedef struct {
  uint8_t type;          /* Armazenado em 1 byte para melhor densidade de cache */
  uint16_t value_index;  /* Índice no array de valores (apenas para TOKEN_NUMBER) */
} Token; /* Total: 3 bytes (packed; alinhamento da struct depende da plataforma) */
```

- **Finalidade**: Representar um token individual de forma muito compacta
- **type**: Armazenado como `uint8_t` (1 byte) para melhorar densidade por cache line
- **value_index**: Se `type == TOKEN_NUMBER`, índice no array separado de valores; caso contrário, não usado
- **Otimização**: Token compacto reduz uso de memória e melhora locality durante avaliação
- **Exemplo**: `{TOKEN_NUMBER, 0}` (valor está em `values[0]`) ou `{TOKEN_SIN, 0}`

**Por que separar valores?**
- Maioria dos tokens não tem valores (operadores, funções, variáveis)
- Valores numéricos ficam em array denso separado
- **2x mais tokens** cabem por cache line (8 vs 4)
- **Economia de 38-40%** de memória em expressões típicas
- Melhor locality de referência durante avaliação
- **type**: Qual tipo de token é
- **value**: Se `type == TOKEN_NUMBER`, contém o valor numérico; caso contrário, ignorado
- **Exemplo**: `{TOKEN_NUMBER, 3.14}` ou `{TOKEN_SIN, 0.0}`

---

### `parser.h` / `parser.c`

**Responsabilidade**: 
- Tokenizar strings de expressões matemáticas
- Validar sintaxe básica
- Detectar erros (funções desconhecidas, variáveis misturadas, etc.)
- Converter tokens para RPN (Fase 2)

#### Tipos Customizados

##### `enum ParserError`
```c
typedef enum {
    PARSER_OK = 0,                  /* Sucesso */
    PARSER_UNKNOWN_FUNCTION = 1,    /* Função não reconhecida (ex: "cossecante") */
    PARSER_UNKNOWN_VARIABLE = 2,    /* Variável não reconhecida */
    PARSER_MIXED_VARIABLES = 3,     /* Mistura de variáveis (ex: "x + theta") */
    PARSER_SYNTAX_ERROR = 4,        /* Erro de sintaxe geral (parênteses, etc.) */
    PARSER_MEMORY_ERROR =  (Otimizado)
```c
typedef struct {
    Token *tokens;          /* Array dinâmico de tokens */
    int size;               /* Número de tokens atualmente no buffer */
    int capacity;           /* Espaço alocado (para realocar dinamicamente) */
    
    /* Array separado para valores numéricos (cache-friendly) */
    double *values;         /* Array de valores numéricos */
    int values_size;        /* Número de valores */
    int values_capacity;    /* Capacidade do array de valores */
} TokenBuffer;
```

- **Finalidade**: Container dinâmico para armazenar lista de tokens e valores
- **Gerenciamento**: Parser gerencia alocação/desalocação de ambos os arrays
- **Crescimento**: Tokens começam com 64, values com 16; ambos dobram quando necessário
- **Otimização**: Separação dos valores reduz uso de memória e melhora cache locality
```c
typedef struct {
    Token *tokens;      /* Array dinâmico de tokens */
    int size;           /* Número de tokens atualmente no buffer */
    int capacity;       /* Espaço alocado (para realocar dinamicamente) */
} TokenBuffer;
```

- **Finalidade**: Container dinâmico para armazenar lista de tokens
- **Gerenciamento**: Parser gerencia alocação/desalocação
- **Crescimento**: Começa com 64, dobra quando necessário

#### Variáveis Globais

##### `LocaleConfig parser_locale`
```c
extern LocaleConfig parser_locale;  /* Configuração global no parser.c */
```
- **Padrão**: `LOCALE_POINT`
- **Como trocar**: `parser_set_locale(LOCALE_COMMA);`

#### Funções

##### `void parser_set_locale(LocaleConfig locale)`
- **Objetivo**: Configurar marca decimal globalmente
- **Entrada**: 
  - `locale` (LocaleConfig): `LOCALE_POINT` ou `LOCALE_COMMA`
- **Saída**: Nenhuma (void)
- **Efeito colateral**: Modifica `parser_locale` global
- **Exemplo**:
  ```c
  parser_set_locale(LOCALE_COMMA);
  parser_tokenize("3,14+x", &buf);  // Agora aceita vírgula
  ```

##### `ParserError parser_tokenize(const char *expr, TokenBuffer *output)`
- **Objetivo**: Converter string em lista de tokens
- **Entrada**:
  - `expr` (const char*): String com expressão (ex: `"sin(x)*2+x"`)
  - `output` (TokenBuffer*): Pointer para buffer que receberá tokens
- **Saída**: 
  - `ParserError`: Tipo de sucesso ou erro
  - `output`: Preenchido com tokens se sucesso
- **Características especiais**:
  - **Operadores unários**:
    - `-` (negação): agora representado internamente como um token unário `TOKEN_NEG` (prefix).
      - Critérios para ser unário: início da expressão, após `(`, ou após outro operador/unário (`+`, `-`, `*`, `/`, `^`, `neg`).
      - Implementação: o parser emite `TOKEN_NEG` em contexto unário em vez de inserir `0` antes do `-`. No RPN `TOKEN_NEG` é tratado como uma função unária de alta precedência.
      - Vantagem: encadeamentos como `--x`, `---x`, `-+x` são avaliados corretamente (`--x` = x, `---x` = -x).
    - `+` (positivo/unário): é tratado como no-op (ignorado) quando detectado em contexto unário; `+x`, `(+x)`, `x+ +3` funcionam como esperado.
    - Exemplos: `-x`, `2*(-x)`, `sin(-x)`, `x+-3`, `--x`, `---x` todos são suportados corretamente
- **Validações internas**:
  1. Tokeniza caractere por caractere
  2. Valida variáveis (não mistura x, theta, t)
  3. Valida sintaxe (parênteses balanceados)
  4. Retorna erro se alguma validação falhar
- **Pós-condição**: Se retorna `PARSER_OK`, `output` contém tokens válidos e terminados com `TOKEN_END`
- **Exemplo**:
  ```c
  TokenBuffer buf;
  ParserError err = parser_tokenize("sin(x)", &buf);
  if (err == PARSER_OK) {
      // buf.tokens = [SIN, LPAREN, VAR_X, RPAREN, END]
      debug_print_tokens(&buf);
  }
  ```

##### `ParserError parser_to_rpn(TokenBuffer *tokens, TokenBuffer *rpn)`
- **Objetivo**: Converter tokens infixa para RPN usando algoritmo Shunting Yard
- **Entrada**:
  - `tokens` (TokenBuffer*): Tokens em notação infixa
  - `rpn` (TokenBuffer*): Buffer para receber RPN (será inicializado automaticamente)
- **Saída**: `ParserError` (PARSER_OK, PARSER_MEMORY_ERROR, PARSER_SYNTAX_ERROR)
- **Status**: ✅ Implementado (Shunting Yard de Dijkstra)
- **Algoritmo**: 
  - Usa pilha de operadores e fila de saída
  - Números/variáveis/constantes → saída direta
  - Funções → empilha
  - `(` → empilha
  - `)` → desempilha até `(`, depois aplica função (se houver)
  - Operadores → desempilha por precedência, depois empilha
  - **Precedências**: `^` (4), `*` `/` (3), `+` `-` (2)
  - **Associatividade**: `^` é associativo à direita, outros à esquerda
- **Exemplo**:
  ```c
  TokenBuffer tokens, rpn;
  parser_tokenize("sin(x)*2+x", &tokens);
  parser_to_rpn(&tokens, &rpn);
  // rpn.tokens = [x, sin, 2, *, x, +, END]
  // Equivale a: x sin 2 * x + (tokens e valores)
- **Entrada**: `buf` (TokenBuffer*)
- **Saída**: Nenhuma (void)
- **Crítico**: Chamar após uso para evitar memory leak
- **Nota**: Libera tanto o array de tokens quanto o array de valores
- **Notas**:
  - Aloca memória internamente para `rpn`
  - Sempre chame `parser_free_buffer(&rpn)` após uso
  - Não modifica o buffer de entrada `tokens`

##### `void parser_init_buffer(TokenBuffer *buf)`
- **Objetivo**: Inicializar buffer vazio
- **Entrada**: `buf` (TokenBuffer*) - buffer não inicializado
- **Saída**: Nenhuma (void)
- **Efeito**: Aloca `capacity=64`, `size=0`
- **Nota**: Chamado automaticamente por `parser_tokenize()`, mas útil para uso manual

##### `void parser_free_buffer(TokenBuffer *buf)`
- **Objetivo**: Liberar memória de buffer
- **Entrada**: `buf` (TokenBuffer*)
- **Saída**: Nenhuma (void)
- **Crítico**: Chamar após uso para evitar memory leak
- **Exemplo**:
  ```c
  TokenBuffer buf;
  parser_tokenize("x+1", &buf);
  // ... usar buf ...
  parser_free_buffer(&buf);  // Libera
  ```

##### `int parser_add_token(TokenBuffer *buf, Token token)`
- **Objetivo**: Adicionar token ao buffer (com realocação automática)
- **Entrada**:
  - `buf` (TokenBuffer*): Buffer
  - `token` (Token): Token a adicionar
- **Saída**: 
  - `int`: 1 se sucesso, 0 se erro (memória)
- **Nota**: Função auxiliar, raramente usada diretamente

---

### `debug.h` / `debug.c`

**Responsabilidade**: Funções de inspeção e visualização para debug/aprendizado.

**Observação importante**: O `debug_print_bytecode()` gera bytecode compactado (1 byte por token), mas os valores numéricos de `TOKEN_NUMBER` precisam ser tratados separadamente em uma implementação completa. O bytecode atual é para visualização e aprendizado.

#### Funções

##### `void debug_print_hexdump(const unsigned char *data, int len)`
- **Objetivo**: Exibir bytes em formato hexadecimal (estilo hexdump)
- **Entrada**:
  - `data` (const unsigned char*): Buffer de bytes
  - `len` (int): Número de bytes
- **Saída**: Nenhuma (imprime em stdout)
- **Formato**: 
  ```
  --- HEX DUMP ---
  0000: 96 28 81 29 2A 02 2B 81
  0008: ...
  ```
- **Uso**: Para visualizar bytecode dos tokens (cast para unsigned char*)

##### `void debug_print_tokens(const TokenBuffer *buf)`
- **Objetivo**: Exibir tokens em formato legível
- **Entrada**: `buf` (const TokenBuffer*) - buffer de tokens
- **Saída**: Nenhuma (imprime em stdout)
- **Formato**:
  ```
  --- TOKENS (5) ---
  [ 0] sin          (byte: 150)
  [ 1] (            (byte: 40)
  [ 2] x            (byte: 129)
  [ 3] )            (byte: 41)
  [ 4] END
  ```
- **Uso**: Debug/aprendizado para entender tokenização

##### `void debug_print_bytecode(const TokenBuffer *buf)`
- **Objetivo**: Gerar e exibir bytecode compactado dos tokens (sem padding de struct)
- **Entrada**: `buf` (const TokenBuffer*) - buffer de tokens
- **Saída**: Nenhuma (imprime em stdout)
- **Formato**:
  ```
  --- BYTECODE COMPACTADO ---
  Sequência de bytes: 96 28 81 29 2A 80 2B 81 FF 
  
  Interpretação:
    [0] 0x96 = 150  ← sin
    [1] 0x28 =  40  ← (
    [2] 0x81 = 129  ← x
    [3] 0x29 =  41  ← )
    [4] 0x2A =  42  ← *
    [5] 0x80 = 128  ← NUMBER (valor: 2)
    [6] 0x2B =  43  ← +
    [7] 0x81 = 129  ← x
    [8] 0xFF = 255  ← END
  
  Hex dump compactado:
  0000: 96 28 81 29 2A 80 2B 81 FF
  ```
- **Uso**: Visualizar bytecode real sem overhead de structs (ideal para entender compactação)
- **Diferença**: Extrai apenas os bytes de TokenType, não toda a struct Token (16 bytes → 1 byte por token)

##### `const char* debug_token_name(TokenType type)`
- **Objetivo**: Converter TokenType em string descritiva
- **Entrada**: `type` (TokenType) - tipo do token
- **Saída**: `const char*` - string (ex: "sin", "+", "NUMBER")
- **Exemplo**:
  ```c
  debug_token_name(TOKEN_SIN);    // Retorna "sin"
  debug_token_name(TOKEN_PLUS);   // Retorna "+"
  debug_token_name(TOKEN_NUMBER); // Retorna "NUMBER"
  ```

---

### `evaluator.h` / `evaluator.c`

**Responsabilidade**: Avaliar expressões em RPN (Reverse Polish Notation) e calcular resultados numéricos.

#### Tipos Customizados

##### `enum EvalError`
```c
typedef enum {
    EVAL_OK = 0,
    EVAL_STACK_ERROR,           /* Pilha vazia ou múltiplos valores no final */
    EVAL_DIVISION_BY_ZERO,      /* Divisão por zero */
    EVAL_DOMAIN_ERROR,          /* Domínio inválido */
    EVAL_MATH_ERROR             /* Overflow, NaN */
} EvalError;
```
- **Finalidade**: Identificar tipo de erro durante avaliação
- **EVAL_DIVISION_BY_ZERO**: Separado para permitir estratégias especiais (limite, stencil, marcar descontinuidade)
- **EVAL_DOMAIN_ERROR**: sqrt negativo, log≤0, asin/acos fora de [-1,1], etc.

##### `struct EvalResult`
```c
typedef struct {
    EvalError error;
    double value;
} EvalResult;
```
- **Finalidade**: Retornar resultado e status de erro
- **value**: Válido apenas se `error == EVAL_OK`

#### Funções

##### `EvalResult evaluator_eval_rpn(const TokenBuffer *rpn, double var_value)`
- **Objetivo**: Avaliar expressão RPN com valor para a variável
- **Entrada**:
  - `rpn` (const TokenBuffer*): Expressão em RPN
  - `var_value` (double): Valor para x, theta ou t
- **Saída**: `EvalResult` (erro + valor)
- **Otimização**: Usa pilha **estática** de 64 níveis (sem malloc/free por avaliação)
  - Overhead: ~512 bytes na stack
  - Performance: **2-3x mais rápido** que com alocação dinâmica
  - Suficiente para expressões com até 64 níveis de profundidade (mais que adequado)
- **Algoritmo**:
  1. Cria pilha estática de doubles `[64]`
  2. Para cada token:
     - Número → busca valor em `rpn->values[token.value_index]`, empilha
     - Variável → empilha var_value
     - Constante (pi, e) → empilha valor
     - Operador → desempilha 2, calcula, empilha
     - Função → desempilha 1, calcula, empilha
  3. Retorna valor final (deve sobrar exatamente 1 na pilha)

- **Implementação/Performance**: As rotinas quentes do avaliador (`apply_operator`, `apply_function`, etc.) são marcadas como `static inline` e o laço de execução usa um `switch` sobre `token.type`. Além disso, `Token.type` é armazenado como `uint8_t` para aumentar a densidade por cache line e reduzir mispredições de branch.
- **Exemplo**:
  ```c
  TokenBuffer rpn;
  parser_tokenize("sin(x)*2+1", &tokens);
  parser_to_rpn(&tokens, &rpn);
  
  EvalResult result = evaluator_eval_rpn(&rpn, 1.0);  // x=1
  if (result.error == EVAL_OK) {
      printf("Resultado: %g\n", result.value);  // 2.68294
  }
  ```
- **Funções suportadas** (20 total):
  - Trigonométricas: sin, cos, tan
  - Inversas: asin, acos, atan
  - Hiperbólicas: sinh, cosh, tanh
  - Hiperbólicas inversas: asinh, acosh, atanh
  - Exponencial: exp (e^x)
  - Logaritmos: log (ln), log10
  - Outras: abs, sqrt, ceil, floor, frac

---

### `main.c`

**Responsabilidade**: Programa de teste/protótipo que demonstra o parser em ação.

**Estrutura**:
1. Função auxiliar `test_expression(const char *expr)` que:
   - Tokeniza a expressão
   - Exibe tokens em formato legível
   - Exibe bytecode compactado
   - Tenta conversão para RPN (stub)
   - Trata erros

2. Função `main()` que:
   - Executa testes com `LOCALE_POINT`
   - Executa testes com `LOCALE_COMMA`
   - Testa casos de erro

**Como estender**: Adicione novas chamadas a `test_expression()` com novos casos de teste.

---

### Build & Test Framework (PR #1)
O repositório recebeu uma pequena reestruturação para facilitar testes automatizados e o fluxo de build.

- `Makefile` refatorado: alvos unificados e fluxo de testes integrado. Use `make all` para compilar e rodar a suíte demonstrativa.
- Nova pasta `test/`: contém programas de teste (ex.: `test/unary.c`, `test/benchmark.c`, `test/memory.c`). A fonte principal (`src/`) continua a conter a implementação, enquanto `test/` agrega executáveis de verificação.
- Targets relevantes (exemplos):
  - `make all` — compila e executa a suíte de testes demonstrativa (tokenização, RPN, avaliação, análise de memória).
  - `make benchmark` — compila e executa o benchmark de performance.
  - `make memtest` — executa o programa de análise de memória.
  - `make run` — executa o binário principal (quando aplicável).

-- Arquivos de configuração editor/IDE (`.vscode/launch.json`, `.vscode/tasks.json`) podem existir para desenvolvimento local; são opcionais para contribuintes.

Como rodar localmente (exemplo):
```bash
# compila e roda a suíte demonstrativa
make all

# apenas benchmark
make benchmark

# apenas análise de memória
make memtest
```

Essas alterações melhoram a testabilidade do projeto e facilitam integração contínua futura.
## Fluxo de Dados

```
String de entrada
       ↓
parser_tokenize()
       ↓
[Validações] → Erro → return PARSER_ERROR
       ↓
TokenBuffer com tokens
       ↓
debug_print_tokens() [opcional]
       ↓
parser_to_rpn() [Fase 2]
       ↓
TokenBuffer em RPN
       ↓
evaluator_rpn() [Fase 3]
       ↓
double resultado
```

---

## Otimizações de Performance

### 1. Token Compacto (Economia de Memória)

**Problema**: Estrutura original desperdiçava memória
```c
/* Antes: 16 bytes por token */
struct TokenOld {
    TokenType type;    // 4 bytes
    double value;      // 8 bytes
};                     // Total: 16 bytes (com padding)
```

Para expressão `sin(x) + 2 * 3.14` (9 tokens, apenas 2 números):
- Memória antiga: 144 bytes
- Desperdício: 7 tokens × 8 bytes = 56 bytes de doubles não usados

**Solução**: Separar valores em array dedicado
```c
/* Depois: 8 bytes por token */
struct Token {
    TokenType type;        // 4 bytes
    uint16_t value_index;  // 2 bytes
};                         // Total: 8 bytes (com padding)
```

Array separado:
```c
TokenBuffer {
    Token tokens[9];      // 72 bytes
    double values[2];     // 16 bytes
};                        // Total: 88 bytes
```

**Resultados**:
- **Redução por token**: 50% (16 → 8 bytes)
- **Economia em expressões típicas**: 38-40%
- **Tokens por cache line**: 2x mais (8 vs 4 tokens/64 bytes)
- **Benefício**: Melhor locality de referência durante avaliação em loops

### 2. Pilha Estática de Avaliação

**Problema**: `malloc/free` em cada avaliação
```c
/* Antes: alocação dinâmica */
double *stack = malloc(rpn->size * sizeof(double));
// ... avalia expressão ...
free(stack);
```

Em loops de 10 milhões de iterações:
- 10M × (malloc + free) = overhead significativo
- Fragmentação de memória
- Cache misses

**Solução**: Pilha estática de tamanho fixo
```c
/* Depois: array estático */
#define MAX_EVAL_STACK_SIZE 64
double stack[MAX_EVAL_STACK_SIZE];  // ~512 bytes na stack
```

**Resultados**:
- **Performance**: 2-3x mais rápido em loops intensivos
- **Overhead**: ~512 bytes (64 × 8 bytes) - aceitável
- **Capacidade**: 64 níveis de profundidade - mais que suficiente
  - Expressão `x * exp(x)` usa apenas 3 níveis
  - Expressões práticas raramente excedem 10 níveis
- **Sem fragmentação**: Memória na stack é automaticamente gerenciada
- **Sem falhas de alocação**: Sem risco de malloc retornar NULL

### 3. Função exp() Nativa

**Problema**: Usar `e^x` via potenciação é menos eficiente
```c
/* Antes: usando constante e + pow */
e^x  →  TOKEN_CONST_E, TOKEN_VARIABLE_X, TOKEN_POW
     →  avalia: pow(2.718..., x)
```

**Solução**: Função `exp()` nativa da math.h
```c
/* Depois: função dedicada */
exp(x)  →  TOKEN_EXP, TOKEN_VARIABLE_X
        →  avalia: exp(x)  // Otimizada pela libm
```

**Resultados** (benchmark de integração, 10M pontos):
- `e^x`: Overhead de 3.95x vs hardcoded
- `exp(x)`: Overhead de 2.56x vs hardcoded
- **Melhoria**: 35% mais rápido!

### Benchmark Completo

Programa: `make benchmark`

Teste: Integração numérica de `f(x) = x * exp(x)` de 0 a 1 com 10 milhões de pontos

**Resultados** (10M iterações):
```
Parsing:              0.000004s (negligível)
Hardcoded function:   0.039s
Parsed function:      0.101s
Overhead parseado:    2.56x
```

**Análise**:
- Parsing é **instantâneo** (4 microssegundos)
- Overhead de apenas **2.56x** é excelente para um interpretador
- Pilha estática contribui significativamente para a performance
- Token compacto melhora cache hits durante avaliação

---

## Algoritmos Implementados

### Shunting Yard (Dijkstra)

Para uma explicação detalhada e completa do algoritmo Shunting-Yard com exemplos passo a passo, consulte: **[SHUNTING_YARD.md](SHUNTING_YARD.md)**

---

## Fluxo de Dados

```
String de entrada
       ↓
parser_tokenize()
       ↓
[Validações] → Erro → return PARSER_ERROR
       ↓
TokenBuffer com tokens
       ↓
debug_print_tokens() [opcional]
       ↓
parser_to_rpn() [Fase 2]
       ↓
TokenBuffer em RPN
       ↓
evaluator_rpn() [Fase 3]
       ↓
double resultado
```

---

## Checklist de Funcionalidades

### ✅ Fase 1: Tokenização (Completa)
- [x] Tokenização de operadores básicos (+, -, *, /, ^)
- [x] **Suporte a operador unário** - (negativo)
- [x] Tokenização de números (com suporte a locale)
- [x] Tokenização de funções (20 funções matemáticas)
- [x] Tokenização de constantes (pi, e)
- [x] Tokenização de variáveis (x, theta, t)
- [x] Detecção de parênteses
- [x] Validação de variáveis (não mista)
- [x] Validação de sintaxe básica
- [x] Suporte a locale (ponto e vírgula decimal)
- [x] Debug output (hex, tokens)

### Fase 2: RPN ✅
- [x] Algoritmo Shunting Yard
- [x] Suporte a precedência de operadores
- [x] Suporte a associatividade (^ é associativo à direita)
- [x] Suporte a funções

### Fase 3: Avaliação ✅
- [x] Avaliador de RPN (pilha estática)
- [x] Substituição de variáveis
- [x] Cálculo de constantes (pi, e)
- [x] Tratamento de erros matemáticos (divisão por zero, domínio, overflow)
- [x] 20 funções implementadas

### Fase 4: Otimizações ✅
- [x] Token compacto (8 bytes)
- [x] Pilha estática de avaliação
- [x] Função exp() nativa

### Fase 5: Benchmark ✅
- [x] Integração numérica (10M pontos)
- [x] Comparação hardcoded vs parseado
- [x] Análise de memória

### Fase 6: Sistema de Plotagem ✅
- [x] Parser de curvas com auto-detecção (Y=, R=, R**2=, X=;Y=)
- [x] Intervalos customizados com sintaxe `:C,D:`
- [x] **Parser de expressões em intervalos**: Suporte a `pi`, `e`, `-pi`, `-e`, `n*pi`, `n*e`, frações `a/b`
- [x] **Token ln**: Adicionado `ln` como alias para `log` (logaritmo natural)
- [x] Geração de 80 amostras com conversão de coordenadas
- [x] Renderizador CSV para análise tabular
- [x] Renderizador SVG com grid profissional
- [x] **Filtragem de valores extremos**: MAX_COORD = 1e6 para proteção contra singularidades
- [x] Bounding box automático com proteção contra infinitos
- [x] CLI completo com canvas ajustável
- [x] **77 curvas históricas do ZX81**: Script `gerar_77_curvas.sh` recria todas as curvas originais

---

## Notas de Desenvolvimento

### Convenções de Código
- Funções privadas (internas a um módulo): `static`
- Funções públicas (header .h): Sem `static`
- Variáveis globais: Poucas e bem documentadas (ex: `parser_locale`)
- Erro/sucesso: Enums `*Error`, retorno `0` ou enums

### Memory Management
- Sempre liberar com `parser_free_buffer()` após uso
- Parser aloca internamente, usuário não precisa alocar TokenBuffer

### Extensão Futura

**Sistema de ranges para extensibilidade:**

O projeto usa **ranges de valores** para permitir adição de funções, variáveis e constantes sem modificar a lógica de parsing:

```c
/* Ranges definidos em tokens.h */
#define TOKEN_VARIABLE_START  129
#define TOKEN_VARIABLE_END    138   /* 10 slots disponíveis */

#define TOKEN_CONST_START     140
#define TOKEN_CONST_END       159   /* 20 slots disponíveis */

#define TOKEN_FUNCTION_START  160
#define TOKEN_FUNCTION_END    199   /* 40 slots disponíveis */
```

**Para adicionar nova função** (ex: "log"):
1. Em `tokens.h`: `TOKEN_LOG = 165` (dentro do range 160-199)
2. Em `parser.c`: `CHECK_KEYWORD("log", TOKEN_LOG)`
3. Em `debug.c`: Case no `debug_token_name()`
4. No avaliador (Fase 3): Case para calcular `log()`

**Não precisa modificar**: `is_function()`, `is_variable()`, `is_constant()` - usam ranges!

**Para adicionar nova variável** (ex: "r"):
1. Em `tokens.h`: `TOKEN_VARIABLE_R = 132` (dentro do range 129-138)
2. Em `parser.c`: `CHECK_KEYWORD("r", TOKEN_VARIABLE_R)`
3. Em `debug.c`: Case no `debug_token_name()`

**Para adicionar nova constante** (ex: "phi" = número de ouro):
1. Em `tokens.h`: `TOKEN_CONST_PHI = 142` (dentro do range 140-159)
2. Em `parser.c`: `CHECK_KEYWORD("phi", TOKEN_CONST_PHI)`
3. Em `debug.c`: Case no `debug_token_name()`
4. No avaliador (Fase 3): Retornar valor `1.618033988749...`

---

## Sistema de Plotagem (Fase 6)

### `multicurvas_plot.h` / `multicurvas_plot.c`

**Responsabilidade**: Parser secundário para curvas matemáticas e geração de amostras.

#### Estruturas

```c
typedef enum {
    PLOT_CARTESIAN,    // Y=f(x)
    PLOT_POLAR_R,      // R=f(t)
    PLOT_POLAR_R2,     // R**2=f(t)
    PLOT_PARAMETRIC    // X=f(t);Y=g(t)
} PlotType;

typedef struct {
    PlotType type;
    char *expr1;           // Primeira expressão
    char *expr2;           // Segunda expressão (apenas paramétrico)
    double C, D;           // Intervalo [C,D]
    int has_interval;      // 1 se intervalo foi especificado
    int samples;           // Número de pontos (padrão: 80)
} Plot;

typedef struct {
    double *x;             // Coordenadas X (cartesianas)
    double *y;             // Coordenadas Y (cartesianas)
    int *status;           // Status de cada ponto (0=ok, 1=erro)
    int count;             // Pontos válidos
    int capacity;          // Capacidade alocada
} PlotData;
```

#### Funções Principais

**`Plot *plot_parse_text(const char *input, char **errmsg)`**
- Parse de entrada: detecta tipo, extrai expressões e intervalo
- Sintaxe de intervalo: `:C,D:` no final (ex: `"Y=x*x:-2,3:"`)
- **Expressões em intervalos**: Suporte a `pi`, `e`, `-pi`, `-e`, `n*pi`, `n*e`, frações `a/b`
  - Implementado via `eval_simple_expr()` que substitui `sscanf()`
  - Exemplos: `":1/2,2*pi:"`, `":-pi,pi:"`, `":0.1,3*pi/2:"`
- Retorna `Plot*` ou `NULL` com mensagem de erro

**`PlotData *plot_generate_samples(const Plot *plot, char **errmsg)`**
- Compila expressões para RPN
- Gera 80 pontos (padrão) no intervalo
- Converte coordenadas polares/paramétricas para cartesianas
- Intervalos padrão:
  - Cartesiano: [-10, 10]
  - Polar: [0.004π, 2π]
  - Paramétrico: [0, 2π]

**Conversões de Coordenadas:**
- Polar: `x = r*cos(t)`, `y = r*sin(t)`
- Polar R²: `r = sqrt(f(t))` (apenas se f(t) ≥ 0)
- Paramétrico: direto de `(f(t), g(t))`

### `render.h` / `render.c`

**Responsabilidade**: Renderizadores de saída (CSV e SVG).

#### Funções

**`void render_csv(const PlotData *data)`**
- Saída simples em formato CSV
- Duas colunas: x,y
- Para análise externa ou importação

**`void render_svg(const PlotData *data, const char *title, int canvas_w, int canvas_h)`**
- Gera SVG completo com grid profissional
- Canvas ajustável (800×600 padrão)
- Área de plotagem: 80% do canvas (20% margem)
- Transformação afim: coordenadas matemáticas → pixels
- **Grid**:
  - Linhas principais: cada 1.0 unidade (dados)
  - Tics menores: cada 0.2 unidades
  - Eixos destacados em X=0, Y=0
- **Filtragem de valores extremos**:
  - `#define MAX_COORD 1e6` - Limite para coordenadas válidas
  - Proteção contra singularidades: ignora pontos com |x| ou |y| > 10^6
  - Verifica `isfinite()` para evitar NaN/Inf
  - Evita loops infinitos em grid quando curva tem valores extremos
- **Cores configuráveis** (#defines):
  - `COLOR_BACKGROUND` - Fundo branco (#ffffff)
  - `COLOR_GRID_MAJOR` - Grid principal (#d0d0d0)
  - `COLOR_GRID_MINOR` - Tics menores (#e8e8e8)
  - `COLOR_AXES` - Eixos (#808080)
  - `COLOR_CURVE` - Curva (#0066cc)
- **Limites automáticos**: Bounding box dos dados com filtragem

### `main.c`

**Responsabilidade**: CLI para geração de gráficos.

#### Uso

```bash
./build/multicurvas <expressão> [formato] [largura] [altura]
```

**Argumentos:**
- `expressão` - Obrigatório (ex: `"Y=sin(x)"`)
- `formato` - Opcional: `csv` ou `svg` (padrão: svg)
- `largura` - Opcional: largura do canvas SVG (padrão: 800)
- `altura` - Opcional: altura do canvas SVG (padrão: 600)

**Exemplos:**
```bash
# Parábola padrão
./build/multicurvas "Y=x*x" svg > parabola.svg

# Círculo em HD
./build/multicurvas "R=5" svg 1920 1080 > circulo_hd.svg

# Intervalo customizado
./build/multicurvas "Y=sin(x):-3.14,3.14:" svg > seno.svg

# Curva paramétrica
./build/multicurvas "X=cos(t);Y=sin(t)" svg > circulo_param.svg

# CSV para análise
./build/multicurvas "Y=exp(-x/3)" csv > exponencial.csv
```

#### Tipos de Curvas Suportados

| Sintaxe | Tipo | Variável | Exemplo |
|---------|------|----------|---------|
| `Y=f(x)` | Cartesiana | x | `"Y=x*x"` |
| `R=f(t)` | Polar | t | `"R=5"` |
| `R**2=f(t)` | Polar R² | t | `"R**2=cos(2*t)"` |
| `X=f(t);Y=g(t)` | Paramétrica | t | `"X=cos(t);Y=sin(t)"` |

**Notas:**
- Prefixos case-insensitive (`y=`, `Y=`, `r=`, `R=`)

### Sintaxe Original do ZX81 Preservada

#### Parser de Intervalos com Expressões

O sistema suporta a sintaxe original do ZX81 CURVAS nos intervalos, incluindo:

- **Constantes**: `pi`, `e`, `-pi`, `-e`
- **Expressões multiplicativas**: `2*pi`, `3*pi/2`, `5*e`
- **Frações**: `1/2`, `1/10`, `3/4`
- **Números decimais**: `0.1`, `3.14`, `-2.5`

**Implementação**: Função `eval_simple_expr()` em [src/multicurvas_plot.c](src/multicurvas_plot.c#L23-L70)

**Exemplos de intervalos válidos:**
```
Y=sin(x):-pi,pi:                # -π até π
R=2*pi/t:1/10,3:                # 1/10 até 3
Y=ln(x):1/2,e:                  # 1/2 até e
R=4*sin(3*t)/sin(2*t):.1,3*pi/2: # 0.1 até 3π/2
```

#### Token ln (Logaritmo Natural)

Adicionado suporte à função `ln` como alias para `log` (logaritmo natural).

**Implementação**: [src/parser.c](src/parser.c#L129)
```c
CHECK_KEYWORD("ln", TOKEN_LOG);  // Após log10, antes de log
```

**Compatibilidade**: Ambas as sintaxes são válidas:
- `ln(x)` - Sintaxe original ZX81
- `log(x)` - Sintaxe moderna C

#### Tratamento de Singularidades

Curvas com divisões por valores próximos a zero (ex: `R=2/sin(2*t)`) podem gerar coordenadas extremas (±10^16).

**Problema**: Grid com coordenadas extremas causa loops infinitos
```c
// Loop de renderização: y de -10^16 até 100
for (int y = y_start; y <= y_end; y++) { ... }  // Infinito!
```

**Solução**: Filtragem em duas etapas em [src/render.c](src/render.c)

1. **Bounding box** (linhas 31-49):
   ```c
   #define MAX_COORD 1e6
   if (!isfinite(x) || fabs(x) > MAX_COORD) continue;
   if (!isfinite(y) || fabs(y) > MAX_COORD) continue;
   ```
   - Ignora NaN e infinitos
   - Filtra coordenadas com valor absoluto > 10^6
   - Calcula limites apenas para pontos válidos

2. **Renderização de curva** (linhas 161-173):
   ```c
   if (!isfinite(x) || !isfinite(y)) continue;
   if (x < x_min || x > x_max || y < y_min || y > y_max) continue;
   ```
   - Pula pontos fora do bounding box
   - Desenha apenas porções válidas da curva

**Resultado**: Curvas com singularidades renderizam corretamente, mostrando apenas as partes matemáticas válidas.

### Script de Geração das 77 Curvas Históricas

**Arquivo**: [gerar_77_curvas.sh](gerar_77_curvas.sh)

Script bash que recria todas as 77 curvas do programa original ZX81 CURVAS.

**Características**:
- 77 definições de curvas extraídas de `Referencia/Curvas.txt`
- Sintaxe original preservada (pi, ln, frações nos intervalos)
- Timeout de segurança em curvas com divisões
- Saída em diretório `originais/`

**Uso**:
```bash
./gerar_77_curvas.sh          # Gera todas as 77 curvas
./gerar_77_curvas.sh > log    # Com log de progresso
```

**Curvas notáveis**:
- Curva 36: Trissectriz `R=4*sin(3*t)/sin(2*t):.1,1.5:`
- Curva 38: Cruciforme `R=2/sin(2*t):.1,1.5:`
- Curvas 65-77: Variações de Lissajous paramétricas

**Histórico**: Estas curvas eram computadas em um ZX81 de 8-bits com 1KB de RAM nos anos 80. Este projeto recria a funcionalidade completa em C moderno com arquitetura modular.
- Polar: t em radianos (0.004π a 2π padrão)
- R²: apenas valores não-negativos
- Paramétrico: suporta `X=;Y=` ou `Y=;X=` (ordem automática)

---

**Última atualização**: 2026-01-12
