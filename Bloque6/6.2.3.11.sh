#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# 6.2.3.11 Asegurar que los eventos de sesión se recopilan
# -----------------------------------------------------------------------------

set -euo pipefail

ITEM_ID="6.2.3.11"
ITEM_DESC="Asegurar que los eventos de sesión se recopilan"
SCRIPT_NAME="$(basename "$0")"
BLOCK_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="${BLOCK_DIR}/Log"
LOG_FILE="${LOG_DIR}/${ITEM_ID}.log"
RULE_FILE="/etc/audit/rules.d/50-session.rules"

RULES=(
"-w /var/run/utmp -p wa -k session"
"-w /var/log/wtmp -p wa -k session"
"-w /var/log/btmp -p wa -k session"
)

DRY_RUN=0
[[ ${1:-} =~ ^(--dry-run|-n)$ ]] && DRY_RUN=1

log() {
  local msg="$1"
  printf '[%s] %s\n' "$(date +'%F %T')" "$msg" | tee -a "$LOG_FILE"
}

ensure_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "[ERR] Debe ser root" >&2
    exit 1
  fi
}

rule_present() {
  local r="$1"
  grep -hFxq -- "$r" /etc/audit/rules.d/*.rules 2>/dev/null
}

# Inicio
mkdir -p "$LOG_DIR"; :> "$LOG_FILE"
log "[EXEC] Ejecutando $SCRIPT_NAME – $ITEM_ID"
ensure_root

if [[ $DRY_RUN -eq 0 ]]; then
  touch "$RULE_FILE"
  chmod 640 "$RULE_FILE"
  log "[EXEC] Archivo de reglas creado: $RULE_FILE"
fi

for rule in "${RULES[@]}"; do
  if rule_present "$rule"; then
    log "[OK] Regla ya presente: $rule"
  else
    if [[ $DRY_RUN -eq 1 ]]; then
      log "[DRY-RUN] Añadiría regla: $rule"
    else
      echo "$rule" >> "$RULE_FILE"
      log "[EXEC] Regla añadida: $rule"
    fi
  fi
done

log "[SUCCESS] ${ITEM_ID} aplicado correctamente"
log "== Remediación ${ITEM_ID}: ${ITEM_DESC} completada =="
exit 0
