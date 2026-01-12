#!/bin/bash
# Script para gerar as 77 curvas do programa original ZX81 CURVAS
# Baseado em Referencia/Curvas.txt

EXEC="./build/multicurvas"
OUTDIR="originais"
TIMEOUT=5  # timeout de 5 segundos por curva

# Cria diretório de saída
mkdir -p "$OUTDIR"

echo "=== Gerando as 77 Curvas Fantásticas do ZX81 ==="
echo

# 1) Função constante
echo "[1/77] Função constante..."
$EXEC "Y=5" svg > "$OUTDIR/01_funcao_constante.svg"

# 2) Função valor absoluto
echo "[2/77] Função valor absoluto..."
$EXEC "Y=abs(x)" svg > "$OUTDIR/02_valor_absoluto.svg"

# 3) Função linear
echo "[3/77] Função linear..."
$EXEC "Y=x/3+2" svg > "$OUTDIR/03_funcao_linear.svg"

# 4) Circunferência
echo "[4/77] Circunferência..."
$EXEC "R=6" svg > "$OUTDIR/04_circunferencia.svg"

# 5) Elipse
echo "[5/77] Elipse..."
timeout 5 $EXEC "R=6/(2-sin(t))" svg > "$OUTDIR/05_elipse.svg"

# 6) Parábola
echo "[6/77] Parábola..."
$EXEC "Y=x*x:-2,2:" svg > "$OUTDIR/06_parabola.svg"

# 7) Função fracionária
echo "[7/77] Função fracionária..."
$EXEC "Y=1/(x*x):-3,3:" svg > "$OUTDIR/07_funcao_fracionaria.svg"

# 8) Parábola cúbica
echo "[8/77] Parábola cúbica..."
$EXEC "Y=x*x*x:-1.5,1.5:" svg > "$OUTDIR/08_parabola_cubica.svg"

# 9) Parábola semicúbica ou de Neil
echo "[9/77] Parábola semicúbica..."
$EXEC "Y=(x*x)**(1/3)" svg > "$OUTDIR/09_parabola_semicubica.svg"

# 10) Hipérbole
echo "[10/77] Hipérbole..."
timeout 5 $EXEC "R=4/(2-3*cos(t))" svg > "$OUTDIR/10_hiperbole.svg"

# 11) Hipérbole equilátera
echo "[11/77] Hipérbole equilátera..."
$EXEC "Y=1/x:-4,4:" svg > "$OUTDIR/11_hiperbole_equilatera.svg"

# 12) Curva exponencial
echo "[12/77] Curva exponencial..."
$EXEC "Y=1.3**x" svg > "$OUTDIR/12_curva_exponencial.svg"

# 13) Curva logarítmica
echo "[13/77] Curva logarítmica..."
$EXEC "Y=ln(x):.2,2:" svg > "$OUTDIR/13_curva_logaritmica.svg"

# 14) Curva de probabilidade ou de Gauss
echo "[14/77] Curva de Gauss..."
$EXEC "Y=exp(1)**(-x*x):-2,2:" svg > "$OUTDIR/14_curva_gauss.svg"

# 15) Senóide
echo "[15/77] Senóide..."
$EXEC "Y=sin(x):-pi,pi:" svg > "$OUTDIR/15_senoide.svg"

# 16) Co-senóide
echo "[16/77] Co-senóide..."
$EXEC "Y=cos(x):-pi,pi:" svg > "$OUTDIR/16_cosenoide.svg"

# 17) Tangentóide
echo "[17/77] Tangentóide..."
$EXEC "Y=tan(x):-4.7,4.7:" svg > "$OUTDIR/17_tangentoide.svg"

# 18) Secantóide
echo "[18/77] Secantóide..."
$EXEC "Y=1/cos(x):-4.7,4.7:" svg > "$OUTDIR/18_secantoide.svg"

# 19) Inversa da senóide
echo "[19/77] Inversa da senóide..."
$EXEC "Y=asin(x):-1,1:" svg > "$OUTDIR/19_inversa_senoide.svg"

# 20) Inversa da co-senóide
echo "[20/77] Inversa da co-senóide..."
$EXEC "Y=acos(x):-1,1:" svg > "$OUTDIR/20_inversa_cosenoide.svg"

# 21) Inversa da tangentóide
echo "[21/77] Inversa da tangentóide..."
$EXEC "Y=atan(x)" svg > "$OUTDIR/21_inversa_tangentoide.svg"

# 22) Ciclóide de cúspide na origem
echo "[22/77] Ciclóide de cúspide..."
$EXEC "X=t-sin(t);Y=1-cos(t):-2,2:" svg > "$OUTDIR/22_cicloide_cuspide.svg"

# 23) Ciclóide de vértice na origem
echo "[23/77] Ciclóide de vértice..."
$EXEC "X=t+sin(t);Y=1-cos(t):-2,2:" svg > "$OUTDIR/23_cicloide_vertice.svg"

# 24) Ciclóide alongada
echo "[24/77] Ciclóide alongada..."
$EXEC "X=3*t-5*sin(t);Y=3-5*cos(t):-3,3:" svg > "$OUTDIR/24_cicloide_alongada.svg"

# 25) Ciclóide encurtada
echo "[25/77] Ciclóide encurtada..."
$EXEC "X=4*t-3*sin(t);Y=4-3*cos(t):-3,3:" svg > "$OUTDIR/25_cicloide_encurtada.svg"

# 26) Catenária
echo "[26/77] Catenária..."
$EXEC "Y=(exp(1)**x+exp(1)**-x)/2:-2,2:" svg > "$OUTDIR/26_catenaria.svg"

# 27) Epiciclóide de 4 cúspides
echo "[27/77] Epiciclóide de 4 cúspides..."
$EXEC "X=5*cos(t)-cos(5*t);Y=5*sin(t)-sin(5*t)" svg > "$OUTDIR/27_epicicloide_4cuspides.svg"

# 28) Deltóide ou hipociclóide tricúspide
echo "[28/77] Deltóide..."
$EXEC "X=2*cos(t)+cos(2*t);Y=2*sin(t)-sin(2*t)" svg > "$OUTDIR/28_deltoide.svg"

# 29) Astróide ou hipociclóide de 4 cúspides
echo "[29/77] Astróide..."
$EXEC "X=cos(t)*cos(t)*cos(t);Y=sin(t)*sin(t)*sin(t)" svg > "$OUTDIR/29_astroide.svg"

# 30) Evolvente da circunferência
echo "[30/77] Evolvente da circunferência..."
$EXEC "X=5*cos(t)+5*t*sin(t);Y=5*sin(t)-5*t*cos(t)" svg > "$OUTDIR/30_evolvente_circunferencia.svg"

# 31) Concóide de reta ou de Nicodemes
echo "[31/77] Concóide de reta..."
$EXEC "R=(2/cos(t))+3:-1.4,1.4:" svg > "$OUTDIR/31_concoide_reta.svg"

# 32) Cissóide de diocles
echo "[32/77] Cissóide de diocles..."
$EXEC "R=2*tan(t)*sin(t):0,1:" svg > "$OUTDIR/32_cissoide_diocles.svg"

# 33) Estrofóide
echo "[33/77] Estrofóide..."
$EXEC "R=-3*cos(2*t)/(cos(t)):.1,1.4:" svg > "$OUTDIR/33_estrofoide.svg"

# 34) Ofiuróide
echo "[34/77] Ofiuróide..."
$EXEC "R=4*sin(t)-(2*sin(t)*sin(t)/cos(t)):0,1:" svg > "$OUTDIR/34_ofiuroide.svg"

# 35) Folium de Descartes
echo "[35/77] Folium de Descartes..."
timeout 5 $EXEC "R=(6*sin(t)*cos(t))/(sin(t)*sin(t)*sin(t)+cos(t)*cos(t)*cos(t))" svg > "$OUTDIR/35_folium_descartes.svg"

# 36) Trissectriz de Maclaurin
echo "[36/77] Trissectriz de Maclaurin..."
timeout 5 $EXEC "R=4*sin(3*t)/sin(2*t):.1,1.5:" svg > "$OUTDIR/36_trissectriz_maclaurin.svg"

# 37) Quadratriz de Hípias ou de Dinóstrato
echo "[37/77] Quadratriz de Hípias..."
$EXEC "R=(2*t)/(pi*sin(t)):-.2,.5:" svg > "$OUTDIR/37_quadratriz_hipias.svg"

# 38) Cruciforme
echo "[38/77] Cruciforme..."
timeout 5 $EXEC "R=2/sin(2*t):.1,1.5:" svg > "$OUTDIR/38_cruciforme.svg"

# 39) Curva de Gutschoven
echo "[39/77] Curva de Gutschoven..."
$EXEC "R=1/tan(t):.1,1.5:" svg > "$OUTDIR/39_curva_gutschoven.svg"

# 40) Cúbica de Agnesi ou "versiera"
echo "[40/77] Cúbica de Agnesi..."
$EXEC "Y=8/(4+x*x):-5,5:" svg > "$OUTDIR/40_cubica_agnesi.svg"

# 41) Bifolium
echo "[41/77] Bifolium..."
$EXEC "R=5*sin(t)*cos(t)*cos(t)" svg > "$OUTDIR/41_bifolium.svg"

# 42) Lemniscata de Bernoulli
echo "[42/77] Lemniscata de Bernoulli..."
$EXEC "R**2=cos(2*t)" svg > "$OUTDIR/42_lemniscata_bernoulli.svg"

# 43) Lemniscata
echo "[43/77] Lemniscata..."
$EXEC "R**2=sin(2*t)" svg > "$OUTDIR/43_lemniscata.svg"

# 44) Rosácea de 3 folhas
echo "[44/77] Rosácea de 3 folhas..."
$EXEC "R=sin(3*t)" svg > "$OUTDIR/44_rosacea_3folhas.svg"

# 45) Rosácea de 4 folhas
echo "[45/77] Rosácea de 4 folhas..."
$EXEC "R=cos(2*t)" svg > "$OUTDIR/45_rosacea_4folhas.svg"

# 46) Rosácea de 5 folhas
echo "[46/77] Rosácea de 5 folhas..."
$EXEC "R=sin(5*t)" svg > "$OUTDIR/46_rosacea_5folhas.svg"

# 47) Rosácea de 8 folhas
echo "[47/77] Rosácea de 8 folhas..."
$EXEC "R=sin(4*t)" svg > "$OUTDIR/47_rosacea_8folhas.svg"

# 48) Caracol de Pascal
echo "[48/77] Caracol de Pascal..."
$EXEC "R=4*cos(t)+2" svg > "$OUTDIR/48_caracol_pascal.svg"

# 49) Cardióide
echo "[49/77] Cardióide..."
$EXEC "R=4*cos(t)+4" svg > "$OUTDIR/49_cardioide.svg"

# 50) Coclóide
echo "[50/77] Coclóide..."
$EXEC "R=3*sin(t)/t:-2,2:" svg > "$OUTDIR/50_cocloide.svg"

# 51) Nefróide de Freeth
echo "[51/77] Nefróide de Freeth..."
$EXEC "R=1+2*sin(t/2):-2,2:" svg > "$OUTDIR/51_nefroide_freeth.svg"

# 52) Nefróide de Proctor ou Epiciclóide de Huygens
echo "[52/77] Nefróide de Proctor..."
$EXEC "X=5*(3*cos(t)-cos(3*t));Y=5*(3*sin(t)-sin(3*t))" svg > "$OUTDIR/52_nefroide_proctor.svg"

# 53a) Curva de Bowditch ou de Lissajous (a)
echo "[53a/77] Lissajous (a)..."
$EXEC "X=sin(3*t);Y=sin(t)" svg > "$OUTDIR/53a_lissajous_a.svg"

# 53b) Curva de Bowditch ou de Lissajous (b)
echo "[53b/77] Lissajous (b)..."
$EXEC "X=sin(t/2+pi/8);Y=sin(t):0,4:" svg > "$OUTDIR/53b_lissajous_b.svg"

# 53c) Curva de Bowditch ou de Lissajous (c)
echo "[53c/77] Lissajous (c)..."
$EXEC "X=sin(3/2*t);Y=sin(t)" svg > "$OUTDIR/53c_lissajous_c.svg"

# 53d) Curva de Bowditch ou de Lissajous (d)
echo "[53d/77] Lissajous (d)..."
$EXEC "X=sin(2*t);Y=sin(t)" svg > "$OUTDIR/53d_lissajous_d.svg"

# 53e) Curva de Bowditch ou de Lissajous (e)
echo "[53e/77] Lissajous (e)..."
$EXEC "X=sin(3*t+pi/2);Y=sin(t)" svg > "$OUTDIR/53e_lissajous_e.svg"

# 53f) Curva de Bowditch ou de Lissajous (f)
echo "[53f/77] Lissajous (f)..."
$EXEC "X=sin(3*t+pi/4);Y=sin(t)" svg > "$OUTDIR/53f_lissajous_f.svg"

# 53g) Curva de Bowditch ou de Lissajous (g)
echo "[53g/77] Lissajous (g)..."
$EXEC "X=sin(t/2+pi/16);Y=sin(t):0,4:" svg > "$OUTDIR/53g_lissajous_g.svg"

# 54) Espiral de Arquimedes
echo "[54/77] Espiral de Arquimedes..."
$EXEC "R=t:0,3:" svg > "$OUTDIR/54_espiral_arquimedes.svg"

# 55) Espiral parabólica
echo "[55/77] Espiral parabólica..."
$EXEC "R**2=4*t:0,3:" svg > "$OUTDIR/55_espiral_parabolica.svg"

# 56) Espiral logarítmica
echo "[56/77] Espiral logarítmica..."
$EXEC "R=e**(t/5):-5/10,3:" svg > "$OUTDIR/56_espiral_logaritmica.svg"

# 57) Espiral hiperbólica ou recíproca
echo "[57/77] Espiral hiperbólica..."
$EXEC "R=2*pi/t:1/10,3:" svg > "$OUTDIR/57_espiral_hiperbolica.svg"

# 58) Lituus
echo "[58/77] Lituus..."
$EXEC "R**2=pi/t:1/10,4:" svg > "$OUTDIR/58_lituus.svg"

# 59) R=1/4+sin(t)
echo "[59/77] Curva 59..."
$EXEC "R=1/4+sin(t)" svg > "$OUTDIR/59_curva_59.svg"

# 60) R=sin(t/3):0,3:
echo "[60/77] Curva 60..."
$EXEC "R=sin(t/3):0,3:" svg > "$OUTDIR/60_curva_60.svg"

# 61) R=1-ln(t):1/10,4:
echo "[61/77] Curva 61..."
$EXEC "R=1-ln(t):1/10,4:" svg > "$OUTDIR/61_curva_61.svg"

# 62) R=1-sin(3/2*t)
echo "[62/77] Curva 62..."
$EXEC "R=1-sin(3/2*t)" svg > "$OUTDIR/62_curva_62.svg"

# 63) R=sin(t)*cos(2*t)
echo "[63/77] Curva 63..."
$EXEC "R=sin(t)*cos(2*t)" svg > "$OUTDIR/63_curva_63.svg"

# 64) R=sin(2*t)-sin(t)
echo "[64/77] Curva 64..."
$EXEC "R=sin(2*t)-sin(t)" svg > "$OUTDIR/64_curva_64.svg"

# 65) R=sin(2*t):-1/2,1/2:
echo "[65/77] Curva 65..."
$EXEC "R=sin(2*t):-1/2,1/2:" svg > "$OUTDIR/65_curva_65.svg"

# 66) R=sin(4*t):-1/2,1/2:
echo "[66/77] Curva 66..."
$EXEC "R=sin(4*t):-1/2,1/2:" svg > "$OUTDIR/66_curva_66.svg"

# 67) R=2+cos(5*t)
echo "[67/77] Curva 67..."
$EXEC "R=2+cos(5*t)" svg > "$OUTDIR/67_curva_67.svg"

# 68) R=sin(t/2):0,4:
echo "[68/77] Curva 68..."
$EXEC "R=sin(t/2):0,4:" svg > "$OUTDIR/68_curva_68.svg"

# 69) R=t*cos(t):-2.5,2.5:
echo "[69/77] Curva 69..."
$EXEC "R=t*cos(t):-2.5,2.5:" svg > "$OUTDIR/69_curva_69.svg"

# 70) R=sin(t*3/2):-.25,2.93:
echo "[70/77] Curva 70..."
$EXEC "R=sin(t*3/2):-.25,2.93:" svg > "$OUTDIR/70_curva_70.svg"

# 71) R=sin(1.5*t+pi/2):.25,1.77:
echo "[71/77] Curva 71..."
$EXEC "R=sin(1.5*t+pi/2):.25,1.77:" svg > "$OUTDIR/71_curva_71.svg"

# 72) R=cos(t/2):0,4:
echo "[72/77] Curva 72..."
$EXEC "R=cos(t/2):0,4:" svg > "$OUTDIR/72_curva_72.svg"

# 73) R=1/(2*cos(t)):-1,1:
echo "[73/77] Curva 73..."
$EXEC "R=1/(2*cos(t)):-1,1:" svg > "$OUTDIR/73_curva_73.svg"

# 74) R=1-1.5*sin(t)
echo "[74/77] Curva 74..."
$EXEC "R=1-1.5*sin(t)" svg > "$OUTDIR/74_curva_74.svg"

# 75) R=1/cos(t):-1,1:
echo "[75/77] Curva 75..."
$EXEC "R=1/cos(t):-1,1:" svg > "$OUTDIR/75_curva_75.svg"

# 76) R=sin(t)**2+cos(t)**2
echo "[76/77] Curva 76..."
$EXEC "R=sin(t)**2+cos(t)**2" svg > "$OUTDIR/76_curva_76.svg"

# 77) R=1/t:1/4,3:
echo "[77/77] Curva 77..."
$EXEC "R=1/t:1/4,3:" svg > "$OUTDIR/77_curva_77.svg"

echo
echo "✓ Todas as 77 curvas geradas em $OUTDIR/"
echo
ls -lh "$OUTDIR"/*.svg | wc -l
echo "arquivos SVG criados."
