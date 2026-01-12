/* Renderizadores simples: CSV e SVG */
#include "../include/render.h"
#include <math.h>

// Cores configuráveis
#define COLOR_BACKGROUND "#ffffff"
#define COLOR_GRID_MAJOR "#d0d0d0"
#define COLOR_GRID_MINOR "#e8e8e8"
#define COLOR_AXES       "#808080"
#define COLOR_CURVE      "#0066cc"

void render_csv(const PlotData *data) {
    if (!data) return;
    
    printf("x,y\n");
    for (int i = 0; i < data->count; i++) {
        printf("%.6f,%.6f\n", data->x[i], data->y[i]);
    }
}

void render_svg(const PlotData *data, const char *title, int canvas_w, int canvas_h) {
    if (!data || data->count == 0) return;
    
    // Dimensões do canvas e área de plotagem (20% margem, 10% cada lado)
    const double CANVAS_W = (double)canvas_w;
    const double CANVAS_H = (double)canvas_h;
    const double PLOT_W = CANVAS_W * 0.8;   // 80% do canvas
    const double PLOT_H = CANVAS_H * 0.8;   // 80% do canvas
    const double MARGIN_X = (CANVAS_W - PLOT_W) / 2.0;
    const double MARGIN_Y = (CANVAS_H - PLOT_H) / 2.0;
    
    // Calcula bounding box dos dados (com limite para evitar valores extremos)
    #define MAX_COORD 1e6  // Limite razoável para coordenadas
    double minx = data->x[0], maxx = data->x[0];
    double miny = data->y[0], maxy = data->y[0];
    for (int i = 1; i < data->count; i++) {
        double x = data->x[i];
        double y = data->y[i];
        
        // Ignora valores infinitos ou muito grandes (divisão por zero, etc)
        if (!isfinite(x) || fabs(x) > MAX_COORD) continue;
        if (!isfinite(y) || fabs(y) > MAX_COORD) continue;
        
        if (x < minx) minx = x;
        if (x > maxx) maxx = x;
        if (y < miny) miny = y;
        if (y > maxy) maxy = y;
    }
    
    double rangex = maxx - minx;
    double rangey = maxy - miny;
    if (rangex < 0.01) rangex = 1.0;
    if (rangey < 0.01) rangey = 1.0;
    
    #undef MAX_COORD
    
    // Transformação afim: coordenadas de dados -> pixels
    // px = MARGIN_X + (x - minx) * PLOT_W / rangex
    // py = (CANVAS_H - MARGIN_Y) - (y - miny) * PLOT_H / rangey
    #define TO_PX(x) (MARGIN_X + ((x) - minx) * PLOT_W / rangex)
    #define TO_PY(y) ((CANVAS_H - MARGIN_Y) - ((y) - miny) * PLOT_H / rangey)
    
    // Header SVG
    printf("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
    printf("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"%d\" height=\"%d\">\n", canvas_w, canvas_h);
    
    if (title) {
        printf("  <title>%s</title>\n", title);
    }
    
    // Fundo branco
    printf("  <rect width=\"%d\" height=\"%d\" fill=\"%s\"/>\n", canvas_w, canvas_h, COLOR_BACKGROUND);
    
    // Grade principal (1.0 em 1.0)
    printf("  <g stroke=\"%s\" stroke-width=\"1\">\n", COLOR_GRID_MAJOR);
    
    // Linhas verticais (X)
    int x_start = (int)floor(minx);
    int x_end = (int)ceil(maxx);
    for (int ix = x_start; ix <= x_end; ix++) {
        double x = (double)ix;
        double px = TO_PX(x);
        double py_bottom = TO_PY(miny);
        double py_top = TO_PY(maxy);
        printf("    <line x1=\"%.2f\" y1=\"%.2f\" x2=\"%.2f\" y2=\"%.2f\"/>\n",
               px, py_bottom, px, py_top);
    }
    
    // Linhas horizontais (Y)
    int y_start = (int)floor(miny);
    int y_end = (int)ceil(maxy);
    for (int iy = y_start; iy <= y_end; iy++) {
        double y = (double)iy;
        double py = TO_PY(y);
        double px_left = TO_PX(minx);
        double px_right = TO_PX(maxx);
        printf("    <line x1=\"%.2f\" y1=\"%.2f\" x2=\"%.2f\" y2=\"%.2f\"/>\n",
               px_left, py, px_right, py);
    }
    
    printf("  </g>\n");
    
    // Tics menores (0.2 em 0.2)
    printf("  <g stroke=\"%s\" stroke-width=\"0.5\">\n", COLOR_GRID_MINOR);
    
    // Tics verticais
    double x_tic_start = ceil(minx / 0.2) * 0.2;
    for (double xt = x_tic_start; xt <= maxx + 0.01; xt += 0.2) {
        // Pula múltiplos de 1.0
        if (fabs(xt - round(xt)) < 0.01) continue;
        double px = TO_PX(xt);
        double py_bottom = TO_PY(miny);
        double py_top = TO_PY(maxy);
        printf("    <line x1=\"%.2f\" y1=\"%.2f\" x2=\"%.2f\" y2=\"%.2f\"/>\n",
               px, py_bottom, px, py_top);
    }
    
    // Tics horizontais
    double y_tic_start = ceil(miny / 0.2) * 0.2;
    for (double yt = y_tic_start; yt <= maxy + 0.01; yt += 0.2) {
        // Pula múltiplos de 1.0
        if (fabs(yt - round(yt)) < 0.01) continue;
        double py = TO_PY(yt);
        double px_left = TO_PX(minx);
        double px_right = TO_PX(maxx);
        printf("    <line x1=\"%.2f\" y1=\"%.2f\" x2=\"%.2f\" y2=\"%.2f\"/>\n",
               px_left, py, px_right, py);
    }
    
    printf("  </g>\n");
    
    // Eixos em X=0 e Y=0 (destacados)
    int x_zero_visible = (minx <= 0 && maxx >= 0);
    int y_zero_visible = (miny <= 0 && maxy >= 0);
    
    if (x_zero_visible || y_zero_visible) {
        printf("  <g stroke=\"%s\" stroke-width=\"2\">\n", COLOR_AXES);
        
        if (y_zero_visible) {
            // Eixo Y (vertical em X=0)
            double px = TO_PX(0);
            double py_bottom = TO_PY(miny);
            double py_top = TO_PY(maxy);
            printf("    <line x1=\"%.2f\" y1=\"%.2f\" x2=\"%.2f\" y2=\"%.2f\"/>\n",
                   px, py_bottom, px, py_top);
        }
        
        if (x_zero_visible) {
            // Eixo X (horizontal em Y=0)
            double py = TO_PY(0);
            double px_left = TO_PX(minx);
            double px_right = TO_PX(maxx);
            printf("    <line x1=\"%.2f\" y1=\"%.2f\" x2=\"%.2f\" y2=\"%.2f\"/>\n",
                   px_left, py, px_right, py);
        }
        
        printf("  </g>\n");
    }
    
    // Curva (filtra pontos com valores extremos)
    printf("  <polyline fill=\"none\" stroke=\"%s\" stroke-width=\"2\" points=\"", COLOR_CURVE);
    for (int i = 0; i < data->count; i++) {
        double x = data->x[i];
        double y = data->y[i];
        
        // Pula pontos com valores extremos
        if (!isfinite(x) || !isfinite(y)) continue;
        if (x < minx || x > maxx || y < miny || y > maxy) continue;
        
        double px = TO_PX(x);
        double py = TO_PY(y);
        printf("%.2f,%.2f ", px, py);
    }
    printf("\"/>\n");
    
    printf("</svg>\n");
    
    #undef TO_PX
    #undef TO_PY
}
