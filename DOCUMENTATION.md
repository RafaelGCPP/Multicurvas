# Multicurvas - Documentação Técnica

## Visão Geral do Projeto

**Objetivo**: Criar um parser e avaliador de expressões matemáticas (função de uma variável) que seja modular e educativo, recriando funcionalmente o programa de plotagem de gráficos do ZX81 em C moderno com RPN (Reverse Polish Notation).

**Fases planejadas**:
1. ✅ Tokenização + Validação
2. ✅ Conversão para RPN (Shunting Yard)
3. ✅ Avaliador de RPN
4. ⏳ Benchmark e Validação (ODE hardcoded vs parseada)
5. ⏳ Interface de plotagem

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
    /* Operadores (0-127, ASCII direto) */
    TOKEN_PLUS       = '+',    /* 43  */
    TOKEN_MINUS      = '-',    /* 45  */
    TOKEN_MULT       = '*',    /* 42  */
    TOKEN_DIV        = '/',    /* 47  */
    TOKEN_POW        = '^',    /* 94  */
    TOKEN_LPAREN     = '(',    /* 40  */
    TOKEN_RPAREN     = ')',    /* 41  */
    
    /* Especiais (>= 128) */
    TOKEN_NUMBER     = 128,    /* Número literal (valor em Token.value) */
    
    /* Variáveis: range 129-138 (10 slots) */
    TOKEN_VARIABLE_X = 129,    /* Variável x */
    TOKEN_VARIABLE_THETA = 130,/* Variável theta */
    TOKEN_VARIABLE_T = 131,    /* Variável t */
    
    /* Constantes: range 140-159 (20 slots) */
    TOKEN_CONST_PI   = 140,    /* Constante π */
    TOKEN_CONST_E    = 141,    /* Constante e */
    
    /* Funções: range 160-199 (40 slots) */
    TOKEN_SIN        = 160,    /* Função sin() */
    TOKEN_COS        = 161,    /* Função cos() */
    TOKEN_TAN        = 162,    /* Função tan() */
    TOKEN_ABS        = 163,    /* Função abs() */
    TOKEN_SQRT       = 164,    /* Função sqrt() */
    
    TOKEN_END        = 255,    /* Marcador de fim de expressão */
    TOKEN_ERROR      = 256     /* Erro (nunca apareça em output válido) */
} TokenType;
```

- **Estratégia de encoding**:
  - Operadores básicos usam valores ASCII (permite cast direto: `(char)token`)
  - Especiais >= 128 para identificar "bytecodes" da linguagem
  - **Sistema de ranges**: Variáveis (129-138), Constantes (140-159), Funções (160-199)
  - Permite extensibilidade sem modificar funções auxiliares
  
- **Exemplo**: `"sin(x)*2+x"` → `[SIN, 160][LPAREN, 40][VARIABLE_X, 129][RPAREN, 41][MULT, 42][NUMBER, 2][PLUS, 43][VARIABLE_X, 129][END, 255]`

##### `struct Token`
```c
typedef struct {
    TokenType type;     /* Tipo do token */
    double value;       /* Valor (apenas para TOKEN_NUMBER) */
} Token;
```

- **Finalidade**: Representar um token individual
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
    PARSER_MEMORY_ERROR = 5         /* Falha ao alocar memória */
} ParserError;
```

- **Quando retorna cada erro**:
  - `PARSER_UNKNOWN_FUNCTION`: `"cossecante(x)"`, `"log(x)"` (não suportadas)
  - `PARSER_UNKNOWN_VARIABLE`: Variável que não é x, theta ou t
  - `PARSER_MIXED_VARIABLES`: `"x + theta"` (mesma expressão não pode usar múltiplas variáveis)
  - `PARSER_SYNTAX_ERROR`: `"sin(x))"` (parênteses desbalanceados), `"3++5"` (operador duplo)
  - `PARSER_MEMORY_ERROR`: Sem memória para alocar buffer

##### `struct TokenBuffer`
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
  // Equivale a: x sin 2 * x +
  parser_free_buffer(&tokens);
  parser_free_buffer(&rpn);
  ```
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
- **Algoritmo**:
  1. Cria pilha de doubles
  2. Para cada token:
     - Número → empilha value
     - Variável → empilha var_value
     - Constante (pi, e) → empilha valor
     - Operador → desempilha 2, calcula, empilha
     - Função → desempilha 1, calcula, empilha
  3. Retorna valor final (deve sobrar exatamente 1 na pilha)
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
- **Funções suportadas** (19 total):
  - Trigonométricas: sin, cos, tan
  - Inversas: asin, acos, atan
  - Hiperbólicas: sinh, cosh, tanh
  - Hiperbólicas inversas: asinh, acosh, atanh
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

## Algoritmos Implementados

### Shunting Yard (Dijkstra)

**Finalidade**: Converter expressões **infixas** (notação normal) para **RPN** (Reverse Polish Notation / Notação Polonesa Reversa).

**Por que RPN?**
- Mais fácil de avaliar (sem necessidade de parênteses ou precedência)
- Avaliação em pilha única
- Compacto e eficiente

**Exemplo de conversão**:
```
Infixa:  sin(x) * 2 + x
RPN:     x sin 2 * x +
```

**Como funciona**:

1. **Estruturas**:
   - Pilha de operadores (stack)
   - Fila de saída (output)

2. **Regras de processamento**:

   | Token | Ação |
   |-------|------|
   | Número/Variável/Constante | → saída direta |
   | Função (`sin`, `cos`, etc.) | → empilha |
   | `(` | → empilha |
   | `)` | Desempilha até `(`, depois aplica função se houver |
   | Operador | Desempilha operadores de maior/igual precedência, depois empilha |

3. **Precedências** (maior = mais prioritário):
   - `^` (potência): 4
   - `*`, `/`: 3
   - `+`, `-`: 2

4. **Associatividade**:
   - `^`: Associativo à **direita** (2^3^4 = 2^(3^4))
   - Outros: Associativos à **esquerda** (2-3-4 = (2-3)-4)

**Exemplo passo a passo**: `sin(x) * 2 + x`

```
Token    | Pilha        | Saída
---------|--------------|------------------
sin      | [sin]        | []
(        | [sin, (]     | []
x        | [sin, (]     | [x]
)        | [sin]        | [x, sin]      ← aplica sin após )
*        | [*]          | [x, sin]
2        | [*]          | [x, sin, 2]
+        | [+]          | [x, sin, 2, *] ← * tem maior precedência
x        | [+]          | [x, sin, 2, *, x]
END      | []           | [x, sin, 2, *, x, +] ← desempilha tudo
```

**Resultado RPN**: `x sin 2 * x +`

**Avaliação da RPN** (será implementado na Fase 3):
```
Pilha de valores:
x          → [5]           (assumindo x=5)
sin        → [0.958...]    (sin(5))
2          → [0.958, 2]
*          → [1.916...]    (0.958 * 2)
x          → [1.916, 5]
+          → [6.916...]    (1.916 + 5)
```

---

## Checklist de Funcionalidades

### Fase 1: Tokenização ✅
- [x] Tokenização de operadores básicos (+, -, *, /, ^)
- [x] Tokenização de números (com suporte a locale)
- [x] Tokenização de funções (sin, cos, tan, abs, sqrt)
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
- [x] Avaliador de RPN (pilha de doubles)
- [x] Substituição de variáveis
- [x] Cálculo de constantes (pi, e)
- [x] Tratamento de erros matemáticos (divisão por zero, domínio, overflow)
- [x] 19 funções implementadas

### Fase 4: Benchmark e Validação ⏳
- [ ] Comparar performance: ODE hardcoded vs parseada
- [ ] Método de Euler para teste
- [ ] Validação numérica

### Fase 5: Interface de Plotagem ⏳
- [ ] Plotagem de gráficos 2D
- [ ] Coordenadas retangulares, polares, paramétricas
- [ ] Detecção de descontinuidades

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

**Última atualização**: 2026-01-11
