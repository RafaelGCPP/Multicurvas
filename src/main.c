#include <stdio.h>
#include <string.h>
#include "parser.h"
#include "evaluator.h"
#include "debug.h"

/* Função helper para testar uma expressão */
static void test_expression(const char *expr) {
    printf("\n========================================\n");
    printf("Testando: \"%s\"\n", expr);
    printf("========================================\n");
    
    TokenBuffer tokens;
    TokenBuffer rpn;
    
    /* Tokeniza */
    ParserError err = parser_tokenize(expr, &tokens);
    
    if (err != PARSER_OK) {
        printf("ERRO: ");
        switch (err) {
            case PARSER_UNKNOWN_FUNCTION:
                printf("Função desconhecida\n");
                break;
            case PARSER_UNKNOWN_VARIABLE:
                printf("Variável desconhecida\n");
                break;
            case PARSER_MIXED_VARIABLES:
                printf("Variáveis misturadas (não use x, theta, t juntos)\n");
                break;
            case PARSER_SYNTAX_ERROR:
                printf("Erro de sintaxe\n");
                break;
            case PARSER_MEMORY_ERROR:
                printf("Erro de memória\n");
                break;
            default:
                printf("Erro desconhecido (%d)\n", err);
        }
        return;
    }
    
    printf("✓ Tokenização OK\n");
    debug_print_tokens(&tokens);
    
    /* Bytecode compactado */
    debug_print_bytecode(&tokens);
    
    /* Converte para RPN */
    err = parser_to_rpn(&tokens, &rpn);
    if (err == PARSER_OK) {
        printf("✓ Conversão para RPN OK\n");
        debug_print_tokens(&rpn);
        
        /* Avalia com valor de teste */
        double test_value = 1.0;  /* x=1, theta=1, ou t=1 */
        printf("\n--- AVALIAÇÃO (variável = %.2f) ---\n", test_value);
        
        EvalResult eval = evaluator_eval_rpn(&rpn, test_value);
        
        if (eval.error == EVAL_OK) {
            printf("✓ Resultado: %.6g\n", eval.value);
        } else {
            printf("✗ Erro de avaliação: ");
            switch (eval.error) {
                case EVAL_STACK_ERROR:
                    printf("Erro na pilha (expressão mal-formada)\n");
                    break;
                case EVAL_DIVISION_BY_ZERO:
                    printf("Divisão por zero\n");
                    break;
                case EVAL_DOMAIN_ERROR:
                    printf("Domínio inválido\n");
                    break;
                case EVAL_MATH_ERROR:
                    printf("Erro matemático (overflow/NaN)\n");
                    break;
                default:
                    printf("Erro desconhecido\n");
            }
        }
        
        parser_free_buffer(&rpn);
    }
    
    parser_free_buffer(&tokens);
}

int main(void) {
    printf("╔═══════════════════════════════════════════════════════════╗\n");
    printf("║    MULTICURVAS - Parser de Expressões Matemáticas        ║\n");
    printf("║              Fase 1: Tokenizador + RPN                   ║\n");
    printf("╚═══════════════════════════════════════════════════════════╝\n");
    
    /* TESTE 1: Com locale POINT (padrão) */
    printf("\n▶▶▶ TESTE COM LOCALE POINT (ponto decimal) ▶▶▶\n");
    parser_set_locale(LOCALE_POINT);
    
    test_expression("sin(x)*2+x");
    test_expression("9*(theta-pi/2)");
    test_expression("2*e^(-t/2)");
    test_expression("3.14159");
    test_expression("2.5*x+1.75");
    test_expression("0.5^2");
    
    /* TESTE 2: Com locale COMMA */
    printf("\n\n▶▶▶ TESTE COM LOCALE COMMA (vírgula decimal) ▶▶▶\n");
    parser_set_locale(LOCALE_COMMA);
    
    test_expression("sin(x)*2+x");
    test_expression("9*(theta-pi/2)");
    test_expression("2*e^(-t/2)");
    test_expression("3,14159");
    test_expression("2,5*x+1,75");
    test_expression("0,5^2");
    
    /* TESTE 3: Erros diversos */
    printf("\n\n▶▶▶ TESTES COM ERROS ▶▶▶\n");
    parser_set_locale(LOCALE_POINT);
    
    test_expression("cossecante(x)");           /* Função desconhecida */
    test_expression("x + theta");               /* Variáveis misturadas */
    test_expression("sin(x))");                 /* Parênteses desbalanceados */
    test_expression("pi + e");                  /* Constantes */
    test_expression("1/0");                     /* Divisão por zero */
    test_expression("sqrt(-1)");                /* Domínio inválido */
    test_expression("log(0)");                  /* Log de zero (infinito negativo) */
    
    /* TESTE 4: Novas funções */
    printf("\n\n▶▶▶ TESTES COM NOVAS FUNÇÕES ▶▶▶\n");
    
    test_expression("log(e)");                  /* log(e) = 1 */
    test_expression("log10(100)");              /* log10(100) = 2 */
    test_expression("sinh(0)");                 /* sinh(0) = 0 */
    test_expression("asin(0.5)");               /* asin(0.5) ≈ 0.523599 (π/6) */
    test_expression("ceil(2.3)");               /* ceil(2.3) = 3 */
    test_expression("floor(2.7)");              /* floor(2.7) = 2 */
    test_expression("frac(3.14)");              /* frac(3.14) = 0.14 */
    
    printf("\n╔═══════════════════════════════════════════════════════════╗\n");
    printf("║                    Testes Completos                       ║\n");
    printf("╚═══════════════════════════════════════════════════════════╝\n");
    
    return 0;
}
