/* Parser secundário para multicurvas: lê entrada do usuário e cria estrutura Plot.
 * 
 * Usa funções C padrão: strdup(), sscanf(), strchr()
 * O parser de expressões já lida com espaços, então não precisamos trim complexo.
 */

#define _POSIX_C_SOURCE 200809L
#define _DEFAULT_SOURCE

#include "../include/multicurvas_plot.h"
#include "../include/parser.h"
#include "../include/evaluator.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <math.h>
#include <ctype.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

/* Avalia uma expressão simples do intervalo (número, pi, -pi, frações, n*pi, etc.) */
static int eval_simple_expr(const char *expr, double *result) {
    char *endptr;
    double val;
    
    // Remove espaços
    while (*expr && isspace(*expr)) expr++;
    if (!*expr) return 0;
    
    // Trata constantes especiais
    if (strncmp(expr, "pi", 2) == 0 && !isalnum(expr[2])) {
        *result = M_PI;
        return 1;
    }
    if (strncmp(expr, "-pi", 3) == 0 && !isalnum(expr[3])) {
        *result = -M_PI;
        return 1;
    }
    if (strncmp(expr, "e", 1) == 0 && !isalnum(expr[1])) {
        *result = M_E;
        return 1;
    }
    if (strncmp(expr, "-e", 2) == 0 && !isalnum(expr[2])) {
        *result = -M_E;
        return 1;
    }
    
    // Trata n*pi ou n*e
    char *star = strchr(expr, '*');
    if (star) {
        double num = strtod(expr, &endptr);
        if (endptr == star) {
            const char *after = star + 1;
            while (*after && isspace(*after)) after++;
            if (strncmp(after, "pi", 2) == 0 && !isalnum(after[2])) {
                *result = num * M_PI;
                return 1;
            }
            if (strncmp(after, "e", 1) == 0 && !isalnum(after[1])) {
                *result = num * M_E;
                return 1;
            }
        }
    }
    
    // Tenta número simples
    val = strtod(expr, &endptr);
    if (endptr != expr && (*endptr == '\0' || isspace(*endptr) || *endptr == ',' || *endptr == ':')) {
        *result = val;
        return 1;
    }
    
    // Tenta fração simples (a/b)
    char *slash = strchr(expr, '/');
    if (slash) {
        double num = strtod(expr, &endptr);
        if (endptr == slash) {
            double den = strtod(slash + 1, &endptr);
            if (den != 0 && (*endptr == '\0' || isspace(*endptr) || *endptr == ',' || *endptr == ':')) {
                *result = num / den;
                return 1;
            }
        }
    }
    
    return 0;
}

/* Extrai intervalo ":C,D:" do final. Retorna 1 se achou, 0 caso contrário. */
static int parse_interval(char *buf, double *C, double *D) {
    // Procura o último ':' (finalizador do intervalo)
    char *ultimo = strrchr(buf, ':');
    if (!ultimo || ultimo == buf) return 0;
    
    // Procura o penúltimo ':' (início do intervalo)
    *ultimo = '\0';  // Trunca temporariamente
    char *anterior = strrchr(buf, ':');
    *ultimo = ':';   // Restaura
    
    if (!anterior) return 0;
    
    // Extrai a substring do intervalo
    char interval[128];
    int len = ultimo - anterior - 1;
    if (len <= 0 || len >= (int)sizeof(interval)) return 0;
    
    strncpy(interval, anterior + 1, len);
    interval[len] = '\0';
    
    // Procura a vírgula separadora
    char *comma = strchr(interval, ',');
    if (!comma) return 0;
    
    *comma = '\0';  // Divide em duas strings
    char *expr_c = interval;
    char *expr_d = comma + 1;
    
    // Avalia as duas expressões
    if (eval_simple_expr(expr_c, C) && eval_simple_expr(expr_d, D)) {
        // Trunca a string antes do intervalo
        *anterior = '\0';
        return 1;
    }
    
    return 0;
}

/* Detecta o tipo de curva olhando o prefixo (case-insensitive) */
static PlotType detectar_tipo(char *expr, char **expr_limpa) {
    // Pula espaços iniciais
    while (*expr && isspace(*expr)) expr++;
    
    // Verifica prefixos (case-insensitive)
    if (strncasecmp(expr, "Y=", 2) == 0) {
        *expr_limpa = strdup(expr + 2);
        return PLOT_CARTESIAN;
    }
    if (strncasecmp(expr, "R**2=", 5) == 0) {
        *expr_limpa = strdup(expr + 5);
        return PLOT_POLAR_R2;
    }
    if (strncasecmp(expr, "R=", 2) == 0) {
        *expr_limpa = strdup(expr + 2);
        return PLOT_POLAR_R;
    }
    if (strncasecmp(expr, "X=", 2) == 0) {
        *expr_limpa = strdup(expr + 2);
        return PLOT_PARAMETRIC;
    }
    
    // Sem prefixo: assume cartesiano
    *expr_limpa = strdup(expr);
    return PLOT_CARTESIAN;
}

Plot *plot_parse_text(const char *input, char **errmsg) {
    if (errmsg) *errmsg = NULL;
    if (!input || !*input) {
        if (errmsg) *errmsg = strdup("entrada vazia");
        return NULL;
    }
    
    // Copia entrada
    char *buf = strdup(input);
    if (!buf) {
        if (errmsg) *errmsg = strdup("memória insuficiente");
        return NULL;
    }
    
    // Extrai intervalo opcional ":C,D:"
    double C = 0, D = 0;
    int tem_intervalo = parse_interval(buf, &C, &D);
    
    // Separa por ';' ou '\n'
    char *e1 = buf, *e2 = NULL;
    char *sep = strpbrk(buf, ";\n\r");
    if (sep) {
        *sep = '\0';
        e2 = sep + 1;
    }
    
    // Aloca estrutura
    Plot *plot = calloc(1, sizeof(Plot));
    if (!plot) {
        if (errmsg) *errmsg = strdup("memória insuficiente");
        free(buf);
        return NULL;
    }
    
    plot->samples = PLOT_DEFAULT_SAMPLES;
    plot->C = C;
    plot->D = D;
    plot->has_interval = tem_intervalo;
    
    // Detecta tipo e processa
    if (!e2) {
        // Uma expressão
        plot->type = detectar_tipo(e1, &plot->expr1);
    } else {
        // Duas expressões: modo paramétrico
        PlotType t1 = detectar_tipo(e1, &plot->expr1);
        PlotType t2 = detectar_tipo(e2, &plot->expr2);
        
        // Se temos X= e Y=, ordena corretamente
        if (t1 == PLOT_PARAMETRIC) {
            plot->type = PLOT_PARAMETRIC;
        } else if (t2 == PLOT_PARAMETRIC) {
            // Inverte ordem
            char *tmp = plot->expr1;
            plot->expr1 = plot->expr2;
            plot->expr2 = tmp;
            plot->type = PLOT_PARAMETRIC;
        } else {
            // Fallback: primeira é X, segunda é Y
            plot->type = PLOT_PARAMETRIC;
        }
    }
    
    free(buf);
    
    if (!plot->expr1) {
        if (errmsg) *errmsg = strdup("não foi possível interpretar a entrada");
        plot_free(plot);
        return NULL;
    }
    
    return plot;
}

void plot_free(Plot *p) {
    if (!p) return;
    free(p->expr1);
    free(p->expr2);
    free(p);
}

void plot_data_free(PlotData *data) {
    if (!data) return;
    free(data->x);
    free(data->y);
    free(data->status);
    free(data);
}

/* Define intervalos padrão conforme programa original ZX81 */
static void definir_intervalo_padrao(PlotType type, double *C, double *D) {
    switch (type) {
        case PLOT_CARTESIAN:
            *C = -10.0; *D = 10.0;
            break;
        case PLOT_POLAR_R:
        case PLOT_POLAR_R2:
            *C = 0.004; *D = 2.0;
            break;
        case PLOT_PARAMETRIC:
            *C = 0.0; *D = 2.0;
            break;
        default:
            *C = -10.0; *D = 10.0;
    }
}

PlotData *plot_generate_samples(const Plot *plot, char **errmsg) {
    if (errmsg) *errmsg = NULL;
    if (!plot || !plot->expr1) {
        if (errmsg) *errmsg = strdup("plot inválido");
        return NULL;
    }
    
    // Define intervalo [C,D]
    double C = plot->C, D = plot->D;
    if (!plot->has_interval) {
        definir_intervalo_padrao(plot->type, &C, &D);
    }
    
    // Para polar, converte para radianos
    int is_polar = (plot->type == PLOT_POLAR_R || plot->type == PLOT_POLAR_R2);
    if (is_polar) {
        C = C * M_PI;
        D = D * M_PI;
    }
    
    // Aloca estrutura de dados
    PlotData *data = calloc(1, sizeof(PlotData));
    if (!data) {
        if (errmsg) *errmsg = strdup("memória insuficiente");
        return NULL;
    }
    
    int n = plot->samples;
    data->x = malloc(n * sizeof(double));
    data->y = malloc(n * sizeof(double));
    data->status = calloc(n, sizeof(int));
    data->capacity = n;
    
    if (!data->x || !data->y || !data->status) {
        if (errmsg) *errmsg = strdup("memória insuficiente");
        plot_data_free(data);
        return NULL;
    }
    
    // Compila expressão(ões)
    TokenBuffer tokens1, rpn1;
    parser_init_buffer(&tokens1);
    parser_init_buffer(&rpn1);
    
    ParserError perr = parser_tokenize(plot->expr1, &tokens1);
    if (perr != PARSER_OK) {
        if (errmsg) *errmsg = strdup("erro ao compilar primeira expressão");
        parser_free_buffer(&tokens1);
        parser_free_buffer(&rpn1);
        plot_data_free(data);
        return NULL;
    }
    
    perr = parser_to_rpn(&tokens1, &rpn1);
    if (perr != PARSER_OK) {
        if (errmsg) *errmsg = strdup("erro ao converter primeira expressão para RPN");
        parser_free_buffer(&tokens1);
        parser_free_buffer(&rpn1);
        plot_data_free(data);
        return NULL;
    }
    
    // Segunda expressão (paramétrico)
    TokenBuffer tokens2, rpn2;
    int tem_expr2 = (plot->type == PLOT_PARAMETRIC && plot->expr2);
    if (tem_expr2) {
        parser_init_buffer(&tokens2);
        parser_init_buffer(&rpn2);
        
        perr = parser_tokenize(plot->expr2, &tokens2);
        if (perr != PARSER_OK) {
            if (errmsg) *errmsg = strdup("erro ao compilar segunda expressão");
            parser_free_buffer(&tokens1);
            parser_free_buffer(&rpn1);
            parser_free_buffer(&tokens2);
            parser_free_buffer(&rpn2);
            plot_data_free(data);
            return NULL;
        }
        
        perr = parser_to_rpn(&tokens2, &rpn2);
        if (perr != PARSER_OK) {
            if (errmsg) *errmsg = strdup("erro ao converter segunda expressão para RPN");
            parser_free_buffer(&tokens1);
            parser_free_buffer(&rpn1);
            parser_free_buffer(&tokens2);
            parser_free_buffer(&rpn2);
            plot_data_free(data);
            return NULL;
        }
    }
    
    // Gera e avalia amostras
    double step = (D - C) / (n - 1);
    int count = 0;
    
    for (int i = 0; i < n; i++) {
        double t = C + i * step;
        EvalResult res1 = evaluator_eval_rpn(&rpn1, t);
        
        if (res1.error != EVAL_OK) {
            data->status[i] = 1;
            continue;
        }
        
        // Converte para coordenadas cartesianas
        if (plot->type == PLOT_CARTESIAN) {
            data->x[count] = t;
            data->y[count] = res1.value;
        } else if (plot->type == PLOT_POLAR_R) {
            double r = res1.value;
            data->x[count] = r * cos(t);
            data->y[count] = r * sin(t);
        } else if (plot->type == PLOT_POLAR_R2) {
            // R**2 = f(t) → R = sqrt(f(t)) se f(t) >= 0
            if (res1.value < 0) {
                data->status[i] = 1;
                continue;
            }
            double r = sqrt(res1.value);
            data->x[count] = r * cos(t);
            data->y[count] = r * sin(t);
        } else if (plot->type == PLOT_PARAMETRIC) {
            if (!tem_expr2) {
                data->status[i] = 1;
                continue;
            }
            EvalResult res2 = evaluator_eval_rpn(&rpn2, t);
            if (res2.error != EVAL_OK) {
                data->status[i] = 1;
                continue;
            }
            data->x[count] = res1.value;
            data->y[count] = res2.value;
        }
        
        count++;
    }
    
    data->count = count;
    
    // Libera buffers
    parser_free_buffer(&tokens1);
    parser_free_buffer(&rpn1);
    if (tem_expr2) {
        parser_free_buffer(&tokens2);
        parser_free_buffer(&rpn2);
    }
    
    return data;
}
