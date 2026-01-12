/* Multicurvas - Gerador de curvas via linha de comando */
#include "../include/multicurvas_plot.h"
#include "../include/render.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void mostrar_uso(const char *prog) {
    fprintf(stderr, "Uso: %s <expressão> [formato] [largura] [altura]\n", prog);
    fprintf(stderr, "\n");
    fprintf(stderr, "Argumentos:\n");
    fprintf(stderr, "  formato  - csv ou svg (padrão: svg)\n");
    fprintf(stderr, "  largura  - largura do canvas SVG (padrão: 800)\n");
    fprintf(stderr, "  altura   - altura do canvas SVG (padrão: 600)\n");
    fprintf(stderr, "\n");
    fprintf(stderr, "Exemplos:\n");
    fprintf(stderr, "  %s \"Y=sin(x)\" svg > sin.svg\n", prog);
    fprintf(stderr, "  %s \"Y=sin(x)\" svg 1600 1200 > sin_hd.svg\n", prog);
    fprintf(stderr, "  %s \"R=6\" csv > circulo.csv\n", prog);
    fprintf(stderr, "  %s \"X=cos(t);Y=sin(t)\" > parametrica.svg\n", prog);
    fprintf(stderr, "\n");
    fprintf(stderr, "Tipos suportados:\n");
    fprintf(stderr, "  Y=f(x)         - Cartesiano\n");
    fprintf(stderr, "  R=f(t)         - Polar\n");
    fprintf(stderr, "  R**2=f(t)      - Polar (raio ao quadrado)\n");
    fprintf(stderr, "  X=f(t);Y=g(t)  - Paramétrico\n");
    fprintf(stderr, "\n");
    fprintf(stderr, "Intervalo opcional: :C,D:\n");
    fprintf(stderr, "  Exemplo: \"Y=1/(x*x):-3,3:\"\n");
    fprintf(stderr, "\n");
    fprintf(stderr, "Nota: Os limites do gráfico são automáticos (bounding box dos dados).\n");
    fprintf(stderr, "      A grade se ajusta aos dados, com linhas a cada 1.0 unidade.\n");
}

int main(int argc, char **argv) {
    if (argc < 2) {
        mostrar_uso(argv[0]);
        return 1;
    }
    
    const char *expressao = argv[1];
    const char *formato = (argc > 2) ? argv[2] : "svg";
    int canvas_w = 800;
    int canvas_h = 600;
    
    // Parse dimensões do canvas (opcionais)
    if (argc > 3) {
        canvas_w = atoi(argv[3]);
        if (canvas_w <= 0) canvas_w = 800;
    }
    if (argc > 4) {
        canvas_h = atoi(argv[4]);
        if (canvas_h <= 0) canvas_h = 600;
    }
    
    // Valida formato
    int is_csv = (strcmp(formato, "csv") == 0);
    int is_svg = (strcmp(formato, "svg") == 0);
    if (!is_csv && !is_svg) {
        fprintf(stderr, "Erro: formato '%s' inválido. Use 'csv' ou 'svg'\n", formato);
        return 1;
    }
    
    // Parse da expressão
    char *errmsg = NULL;
    Plot *plot = plot_parse_text(expressao, &errmsg);
    if (!plot) {
        fprintf(stderr, "Erro ao interpretar expressão: %s\n", errmsg ? errmsg : "desconhecido");
        free(errmsg);
        return 1;
    }
    
    // Gera dados
    PlotData *data = plot_generate_samples(plot, &errmsg);
    if (!data) {
        fprintf(stderr, "Erro ao gerar dados: %s\n", errmsg ? errmsg : "desconhecido");
        free(errmsg);
        plot_free(plot);
        return 1;
    }
    
    // Renderiza
    if (is_csv) {
        render_csv(data);
    } else {
        render_svg(data, expressao, canvas_w, canvas_h);
    }
    
    // Cleanup
    plot_data_free(data);
    plot_free(plot);
    
    return 0;
}
