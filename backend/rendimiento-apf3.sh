#!/usr/bin/env bash
# =====================================================================
# RentaMax — Prueba de CAPACIDAD y rendimiento (APF3, Gestion de Capacidad)
# Mide el servicio REAL desplegado en Render (pruebas no funcionales).
#
# Uso (Git Bash en Windows, dentro de la carpeta backend):
#   export BASE_URL=https://rentamax-backend.onrender.com
#   bash ./rendimiento-apf3.sh
#     -> te pide la clave del OPERADOR (no se muestra ni se guarda).
#   Opcional:  RM_PASS=...   (evita el prompt)   RM_EMAIL=...   NIVELES="50:5 100:10 200:20"
#
# Que hace:
#   1) Despierta Render (plan Free) y mide cuanto tarda el arranque en frio.
#   2) Inicia sesion (JWT) y NO imprime el token.
#   3) Por cada endpoint (/api/health y /api/equipos) y cada nivel "peticiones:concurrentes"
#      lanza las peticiones en paralelo y calcula promedio, p50, p95, p99, maximo, errores y RPS.
#   4) Imprime la ventana de tiempo UTC exacta de la prueba. Con esa ventana se contrastan
#      estos numeros (lado cliente) con CPU/RAM/latencia que reporta Render (lado servidor).
#   5) Guarda el resultado en ../docs/evidencias/rendimiento_apf3_FECHA.txt y un .csv.
# Requiere: bash, curl, xargs, awk (todo viene en Git Bash).
# =====================================================================
set -u
BASE="${BASE_URL:?Define BASE_URL con la URL publica HTTPS del servicio (sin / al final)}"
BASE="${BASE%/}"
EMAIL="${RM_EMAIL:-carlos.mendoza@rentamax.pe}"
NIVELES="${NIVELES:-50:5 100:10 200:20}"
ESPERA_MAX="${ESPERA_MAX:-180}"          # segundos maximos esperando el arranque en frio
if [ -z "${RM_PASS:-}" ]; then
  read -r -s -p "Clave de $EMAIL (no se muestra): " RM_PASS; echo
fi
[ -z "$RM_PASS" ] && { echo "Clave vacia."; exit 1; }

AQUI="$(cd "$(dirname "$0")" && pwd)"
DIR_OUT="$AQUI/../docs/evidencias"; mkdir -p "$DIR_OUT"
SELLO="$(date +%Y%m%d_%H%M)"
TXT="$DIR_OUT/rendimiento_apf3_$SELLO.txt"
CSV="$DIR_OUT/rendimiento_apf3_$SELLO.csv"
TMP="$(mktemp)"; trap 'rm -f "$TMP" "$TMP".*' EXIT
utc() { date -u +%Y-%m-%dT%H:%M:%SZ; }

{
echo "== RentaMax APF3 - prueba de capacidad contra $BASE"
echo "== Cliente: $(uname -s) | curl $(curl --version | head -1 | cut -d' ' -f2) | Inicio local: $(date '+%Y-%m-%d %H:%M:%S %z')"

# ---------- 1) Arranque en frio ----------
echo "-- 1. Despertar el servicio (plan Free se duerme tras 15 min sin trafico)"
T0=$(date +%s)
while :; do
  R="$(curl -s -m 20 -w $'\n%{http_code}' "$BASE/api/health" 2>/dev/null)"; C="${R##*$'\n'}"
  if [ "$C" = "200" ] && [[ "$R" == *'"estado":"UP"'* ]]; then break; fi
  [ $(( $(date +%s) - T0 )) -ge "$ESPERA_MAX" ] && { echo "El servicio no respondio UP en ${ESPERA_MAX}s (ultimo HTTP $C)."; exit 1; }
  sleep 5
done
ARRANQUE=$(( $(date +%s) - T0 ))
echo "   Servicio UP y base de datos UP. Tiempo hasta responder 200: ${ARRANQUE} s"

# ---------- 2) Login ----------
RESP="$(curl -s -m 60 -X POST -H 'Content-Type: application/json' \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$RM_PASS\"}" -w $'\n%{http_code}' "$BASE/api/auth/login")"
CL="${RESP##*$'\n'}"; TOKEN="$(echo "${RESP%$'\n'*}" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')"
[ -z "$TOKEN" ] && { echo "Login fallido (HTTP $CL). Revisa el correo/clave del OPERADOR."; exit 1; }
echo "-- 2. Login $EMAIL -> HTTP $CL, token JWT recibido (no se muestra)"

# ---------- 3) Carga ----------
echo "timestamp_utc,endpoint,peticiones,concurrentes,ok,errores,prom_ms,p50_ms,p95_ms,p99_ms,max_ms,duracion_s,rps" > "$CSV"
VENT_INI="$(utc)"
echo "-- 3. Ventana de prueba (UTC) inicio: $VENT_INI"
printf '\n%-14s %6s %5s %8s %8s %8s %8s %8s %8s %9s %7s\n' ENDPOINT PET CONC OK/TOTAL PROM p50 p95 p99 MAX DURAC RPS
for EP in /api/health /api/equipos; do
  for NIV in $NIVELES; do
    N="${NIV%%:*}"; K="${NIV##*:}"
    : > "$TMP"
    INI=$(date +%s.%N 2>/dev/null || date +%s)
    seq 1 "$N" | xargs -P "$K" -I{} curl -s -o /dev/null -m 60 -w '%{http_code} %{time_total}\n' \
      -H "Authorization: Bearer $TOKEN" "$BASE$EP" >> "$TMP"
    FIN=$(date +%s.%N 2>/dev/null || date +%s)
    TOT=$(wc -l < "$TMP" | tr -d ' ')
    OKS=$(grep -c '^200 ' "$TMP")
    awk '{printf "%.1f\n", $2*1000}' "$TMP" | sort -n > "$TMP.t"
    pct() { awk -v p="$1" '{a[NR]=$1} END{i=p*NR/100; j=int(i); if (j<i) j++; if (j<1) j=1; print a[j]}' "$TMP.t"; }
    PROM=$(awk '{s+=$1} END{printf "%.0f", s/NR}' "$TMP.t")
    P50=$(pct 50); P95=$(pct 95); P99=$(pct 99); MAX=$(tail -1 "$TMP.t")
    DUR=$(awk -v a="$INI" -v b="$FIN" 'BEGIN{printf "%.2f", b-a}')
    RPS=$(awk -v n="$TOT" -v d="$DUR" 'BEGIN{ if (d>0) printf "%.1f", n/d; else print "n/d"}')
    printf '%-14s %6s %5s %8s %6s ms %6s ms %6s ms %6s ms %6s ms %7s s %6s\n' "$EP" "$N" "$K" "$OKS/$TOT" "$PROM" "$P50" "$P95" "$P99" "$MAX" "$DUR" "$RPS"
    echo "$(utc),$EP,$N,$K,$OKS,$((TOT-OKS)),$PROM,$P50,$P95,$P99,$MAX,$DUR,$RPS" >> "$CSV"
    ERR="$(grep -v '^200 ' "$TMP" | awk '{c[$1]++} END{for (k in c) printf "%s x%d  ", k, c[k]}')"
    [ -n "$ERR" ] && echo "    codigos distintos de 200: $ERR"
    sleep 3   # respiro entre niveles para que el CPU del plan Free se enfrie y las metricas se separen
  done
done
VENT_FIN="$(utc)"
echo
echo "-- 4. Ventana de prueba (UTC): $VENT_INI  ->  $VENT_FIN"
echo "   Arranque en frio medido: ${ARRANQUE} s"
echo "   Criterio de la catedra (APF2): respuesta < 500 ms.  Meta SLA propuesta: p95 < 1000 ms con 0 errores."
echo "   Dale esta ventana UTC a Claude para contrastar con CPU/RAM/latencia que mide Render (lado servidor)."
echo "   CSV: $CSV"
} 2>&1 | tee "$TXT"
echo "Guardado en: $TXT"
