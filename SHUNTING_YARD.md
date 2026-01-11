# Algoritmo Shunting-Yard

## Visão Geral

O **Shunting-Yard Algorithm** (Algoritmo do Pátio de Manobras) é um método para converter expressões matemáticas da notação **infixa** (operadores entre operandos) para **notação polonesa reversa** (RPN - Reverse Polish Notation).

Foi criado por **Edsger W. Dijkstra** e publicado em 1961. O nome vem da analogia com pátios de manobra ferroviários, onde vagões são organizados em trilhas auxiliares.

## Por que RPN?

### Notação Infixa (comum)
```
3 + 4 * 2
sin(x) * cos(x)
```
- Natural para humanos
- Requer parênteses para disambiguação
- Requer regras de precedência
- Avaliação complexa (precisa backtracking ou recursão)

### Notação Polonesa Reversa (RPN)
```
3 4 2 * +         (equivale a 3 + 4 * 2 = 11)
x sin x cos *     (equivale a sin(x) * cos(x))
```
- **Não precisa parênteses**
- **Avaliação trivial** com pilha
- Mesma ordem de execução de uma máquina de pilha
- Usada em calculadoras HP e linguagens como PostScript e Forth

## Como Funciona o Algoritmo

### Estruturas de Dados

1. **Fila de saída** (output queue): onde construímos a expressão RPN
2. **Pilha de operadores** (operator stack): armazena operadores e parênteses temporariamente

### Regras do Algoritmo

Para cada token da esquerda para direita:

#### 1. **Número ou Variável**
→ Coloca direto na **fila de saída**

#### 2. **Função** (sin, cos, etc.)
→ Empilha na **pilha de operadores**

#### 3. **Operador** (*, +, -, /, ^)
→ Desempilha operadores da pilha para a saída enquanto:
   - Houver operador no topo da pilha, **E**
   - O operador do topo tiver **precedência maior ou igual** (exceto para `^` que é associativo à direita)

→ Depois empilha o novo operador

#### 4. **Parêntese esquerdo** `(`
→ Empilha na **pilha de operadores**

#### 5. **Parêntese direito** `)`
→ Desempilha todos os operadores até encontrar o `(` correspondente
→ Remove o `(`
→ Se houver uma função no topo, desempilha ela também (pois o parêntese fecha seus argumentos)

#### 6. **Fim da expressão**
→ Desempilha todos os operadores restantes para a saída

### Precedência de Operadores

No nosso sistema:
```c
Precedência 1 (baixa):    +  -
Precedência 2 (média):    *  /
Precedência 3 (alta):     ^
Precedência 4 (mais alta): NEG (negação unária)
Precedência 5 (máxima):   funções (sin, cos, etc.)
```

### Associatividade

- **Esquerda → Direita**: `+`, `-`, `*`, `/`
  - Exemplo: `5 - 3 - 2` = `(5 - 3) - 2` = 0
- **Direita → Esquerda**: `^`
  - Exemplo: `2 ^ 3 ^ 2` = `2 ^ (3 ^ 2)` = 512
 - **Unários (prefix)**: `NEG` (negação) é tratado como operador/função prefixo com **associatividade à direita**.
    - Exemplo: `- - x` → `NEG NEG x` → aplica-se direito-para-esquerda (`-(-x)`)

Nota: O parser representa o `-` unário como `TOKEN_NEG`. Isso evita hacks como inserir `0` antes do `-` e permite encadear unários corretamente.

## Exemplo Passo a Passo

### Expressão: `3 + 4 * 2`

| Passo | Token | Pilha | Saída | Ação |
|-------|-------|-------|-------|------|
| 1 | `3` | `[]` | `[3]` | Número → saída |
| 2 | `+` | `[+]` | `[3]` | Operador → pilha |
| 3 | `4` | `[+]` | `[3, 4]` | Número → saída |
| 4 | `*` | `[+, *]` | `[3, 4]` | `*` tem prec > `+`, empilha |
| 5 | `2` | `[+, *]` | `[3, 4, 2]` | Número → saída |
| 6 | FIM | `[]` | `[3, 4, 2, *, +]` | Desempilha tudo |

**RPN resultante**: `3 4 2 * +`

**Avaliação**:
1. Empilha 3, 4, 2 → pilha: `[3, 4, 2]`
2. `*` desempilha 2 e 4, calcula 8, empilha → pilha: `[3, 8]`
3. `+` desempilha 8 e 3, calcula 11, empilha → pilha: `[11]`
4. **Resultado: 11** ✓

### Expressão: `sin(x) * 2 + cos(x)`

| Passo | Token | Pilha | Saída | Ação |
|-------|-------|-------|-------|------|
| 1 | `sin` | `[sin]` | `[]` | Função → pilha |
| 2 | `(` | `[sin, (]` | `[]` | Parêntese → pilha |
| 3 | `x` | `[sin, (]` | `[x]` | Variável → saída |
| 4 | `)` | `[]` | `[x, sin]` | Fecha parêntese, desempilha até `(`, depois desempilha função |
| 5 | `*` | `[*]` | `[x, sin]` | Operador → pilha |
| 6 | `2` | `[*]` | `[x, sin, 2]` | Número → saída |
| 7 | `+` | `[+]` | `[x, sin, 2, *]` | `+` tem prec < `*`, desempilha `*` |
| 8 | `cos` | `[+, cos]` | `[x, sin, 2, *]` | Função → pilha |
| 9 | `(` | `[+, cos, (]` | `[x, sin, 2, *]` | Parêntese → pilha |
| 10 | `x` | `[+, cos, (]` | `[x, sin, 2, *, x]` | Variável → saída |
| 11 | `)` | `[+]` | `[x, sin, 2, *, x, cos]` | Fecha parêntese, desempilha função |
| 12 | FIM | `[]` | `[x, sin, 2, *, x, cos, +]` | Desempilha `+` |

**RPN resultante**: `x sin 2 * x cos +`

### Expressão com Potenciação: `2 ^ 3 ^ 2`

| Passo | Token | Pilha | Saída | Ação |
|-------|-------|-------|-------|------|
| 1 | `2` | `[]` | `[2]` | Número → saída |
| 2 | `^` | `[^]` | `[2]` | Operador → pilha |
| 3 | `3` | `[^]` | `[2, 3]` | Número → saída |
| 4 | `^` | `[^, ^]` | `[2, 3]` | Associativo à direita, **não** desempilha o primeiro `^` |
| 5 | `2` | `[^, ^]` | `[2, 3, 2]` | Número → saída |
| 6 | FIM | `[]` | `[2, 3, 2, ^, ^]` | Desempilha tudo |

**RPN resultante**: `2 3 2 ^ ^`

**Avaliação**:
1. Empilha 2, 3, 2 → pilha: `[2, 3, 2]`
2. `^` desempilha 2 e 3, calcula 9, empilha → pilha: `[2, 9]`
3. `^` desempilha 9 e 2, calcula 512, empilha → pilha: `[512]`
4. **Resultado: 512** = 2^(3^2) ✓

## Implementação no Multicurvas

### Função Principal: `parser_to_rpn()`

```c
ParserError parser_to_rpn(TokenBuffer *tokens, TokenBuffer *rpn);
```

Localização: [`src/parser.c`](../src/parser.c)

### Características Implementadas

1. **Precedência**:
   ```c
   static int get_precedence(TokenType type) {
       if (type == TOKEN_PLUS || type == TOKEN_MINUS) return 1;
       if (type == TOKEN_MULT || type == TOKEN_DIV) return 2;
       if (type == TOKEN_POW) return 3;
       return 0;
   }
   ```

2. **Associatividade à Direita** para `^`:
   ```c
   if (type == TOKEN_POW) {
       // Para ^: apenas desempilha se precedência for MAIOR
       if (stack_prec <= prec) break;
   } else {
       // Para outros: desempilha se precedência for MAIOR OU IGUAL
       if (stack_prec < prec) break;
   }
   ```

3. **Suporte a Funções**:
   - Funções são empilhadas ao encontrá-las
   - Desempilhadas após o fechamento do parêntese que contém seus argumentos

4. **Validação**:
   - Parênteses balanceados (verificado em `parser_check_syntax()`)
   - Operandos e operadores alternados

## Vantagens do Shunting-Yard

1. **Linear**: O(n) - processa cada token uma vez
2. **Simples**: Usa apenas pilha e fila
3. **Robusto**: Trata precedência e associatividade corretamente
4. **Extensível**: Fácil adicionar novos operadores ou funções

## Referências

- **Paper Original**: Dijkstra, E. W. (1961). "Algol 60 translation: An algol 60 translator for the x1"
- **Wikipedia**: [Shunting-yard algorithm](https://en.wikipedia.org/wiki/Shunting-yard_algorithm)
- **Tutorial Interativo**: [aquarchitect.github.io/swift-algorithm-club](https://aquarchitect.github.io/swift-algorithm-club/Shunting%20Yard/)

---

[← Voltar para Documentação Principal](DOCUMENTATION.md)
