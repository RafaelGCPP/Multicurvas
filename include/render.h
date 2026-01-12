/* Renderizadores de saída para PlotData */
#ifndef RENDER_H
#define RENDER_H

#include "multicurvas_plot.h"
#include <stdio.h>

/* Renderiza dados em formato CSV para stdout */
void render_csv(const PlotData *data);

/* Renderiza dados em formato SVG para stdout com canvas ajustável */
void render_svg(const PlotData *data, const char *title, int canvas_w, int canvas_h);

#endif /* RENDER_H */
