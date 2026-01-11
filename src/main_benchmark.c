#include <stdio.h>
#include "parser.h"

/* Declaração da função de benchmark (implementada em benchmark.c) */
extern void run_benchmark(void);

int main(void) {
    printf("╔═══════════════════════════════════════════════════════════╗\n");
    printf("║      MULTICURVAS - Benchmark de Performance              ║\n");
    printf("╚═══════════════════════════════════════════════════════════╝\n\n");
    
    /* Configura locale padrão */
    parser_set_locale(LOCALE_POINT);
    
    /* Roda o benchmark */
    run_benchmark();
    
    printf("\n╔═══════════════════════════════════════════════════════════╗\n");
    printf("║                  Benchmark Completo                       ║\n");
    printf("╚═══════════════════════════════════════════════════════════╝\n");
    
    return 0;
}
