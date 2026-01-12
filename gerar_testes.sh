#!/bin/bash
# Script de testes: gera várias curvas em SVG

EXEC="./build/multicurvas"
OUTDIR="exemplos"

# Cria diretório de saída
mkdir -p "$OUTDIR"

echo "=== Gerando curvas de teste ==="
echo

# Teste 1: Parábola simples
echo "[1/10] Parábola..."
$EXEC "Y=x*x" svg > "$OUTDIR/01_parabola.svg"

# Teste 2: Seno
echo "[2/10] Seno..."
$EXEC "Y=sin(x)" svg > "$OUTDIR/02_seno.svg"

# Teste 3: Círculo (polar)
echo "[3/10] Círculo..."
$EXEC "R=5" svg > "$OUTDIR/03_circulo.svg"

# Teste 4: Espiral de Arquimedes
echo "[4/10] Espiral de Arquimedes..."
$EXEC "R=t" svg > "$OUTDIR/04_espiral.svg"

# Teste 5: Rosa de 4 pétalas
echo "[5/10] Rosa de 4 pétalas..."
$EXEC "R=sin(2*t)" svg > "$OUTDIR/05_rosa4.svg"

# Teste 6: Lemniscata de Bernoulli
echo "[6/10] Lemniscata..."
$EXEC "R**2=cos(2*t)" svg > "$OUTDIR/06_lemniscata.svg"

# Teste 7: Círculo paramétrico
echo "[7/10] Círculo paramétrico..."
$EXEC "X=3*cos(t);Y=3*sin(t)" svg > "$OUTDIR/07_circulo_param.svg"

# Teste 8: Hipérbole com intervalo customizado
echo "[8/10] Hipérbole (intervalo custom)..."
$EXEC "Y=1/x:-5,5:" svg > "$OUTDIR/08_hiperbole.svg"

# Teste 9: Função exponencial decrescente
echo "[9/10] Exponencial..."
$EXEC "Y=exp(-x/3)" svg > "$OUTDIR/09_exponencial.svg"

# Teste 10: Lissajous (3:2)
echo "[10/10] Curva de Lissajous..."
$EXEC "X=sin(3*t);Y=sin(2*t)" svg > "$OUTDIR/10_lissajous.svg"

echo
echo "✓ Todos os SVGs gerados em $OUTDIR/"
ls -lh "$OUTDIR"/*.svg
