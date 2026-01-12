# Configuração de Cores do SVG

O renderizador SVG usa cores configuráveis definidas em [src/render.c](src/render.c).

## Layout e Proporções

- **Viewport**: Fixo em 800×600 pixels
- **ViewBox**: Ajustado aos dados com margem de 20% em cada lado
- **Isotropia**: NÃO preservada - o gráfico estica para preencher toda a imagem
  - Para círculos perfeitos, use curvas polares (ex: `R=5`) que geram limites quadrados naturalmente
  - Ou ajuste manualmente os intervalos para proporções desejadas

## Cores Padrão

```c
#define COLOR_BACKGROUND "#ffffff"  // Fundo branco
#define COLOR_GRID_MAJOR "#d0d0d0"  // Grid principal (10 divisões) - cinza claro
#define COLOR_GRID_MINOR "#e8e8e8"  // Tics menores - cinza muito claro
#define COLOR_AXES       "#808080"  // Eixos coordenados - cinza médio
#define COLOR_CURVE      "#0066cc"  // Curva plotada - azul
```

## Estilo do Grid

O grid segue o estilo de osciloscópio:

- **10 divisões maiores**: Linhas verticais e horizontais formando grade completa
- **5 subdivisões menores**: Tics apenas nos eixos (não formam linhas completas)
- **Eixos principais**: Destacados quando passam pela origem (X=0, Y=0)

## Espessuras de Linha

As espessuras são proporcionais ao tamanho do viewBox:

- Grid maior: `0.08%` da largura
- Tics menores: `50%` da espessura do grid maior
- Eixos principais: `2x` a espessura do grid maior
- Curva plotada: `3x` a espessura do grid maior

## Personalização

Para alterar as cores, edite as definições em [src/render.c](src/render.c#L5-L9) e recompile:

```bash
make clean && make
```

## Exemplos de Esquemas de Cores

### Tema Escuro
```c
#define COLOR_BACKGROUND "#000000"
#define COLOR_GRID_MAJOR "#333333"
#define COLOR_GRID_MINOR "#222222"
#define COLOR_AXES       "#666666"
#define COLOR_CURVE      "#00ff00"  // Verde fosforescente
```

### Tema Papel Milimetrado
```c
#define COLOR_BACKGROUND "#fffff8"  // Creme
#define COLOR_GRID_MAJOR "#4080ff"  // Azul papel
#define COLOR_GRID_MINOR "#a0c0ff"  // Azul claro
#define COLOR_AXES       "#2050c0"  // Azul escuro
#define COLOR_CURVE      "#ff0000"  // Vermelho
```

### Tema Sépia
```c
#define COLOR_BACKGROUND "#f4e8d8"  // Bege
#define COLOR_GRID_MAJOR "#c0a880"  // Marrom claro
#define COLOR_GRID_MINOR "#d8c8a8"  // Marrom muito claro
#define COLOR_AXES       "#806040"  // Marrom médio
#define COLOR_CURVE      "#402010"  // Marrom escuro
```
