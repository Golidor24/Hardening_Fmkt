#!/usr/bin/env bash
# =============================================================================
# 5.3.3.1.3 – Asegurar que /etc/security/faillock.conf incluya even_deny_root
#            o root_unlock_time=60 (o mayor)
# =============================================================================

set -euo pipefail

ITEM_ID="5.3.3.1.3_FaillockConf"
ITEM_DESC="Asegurar que /etc/security/faillock.conf incluya even_deny_root o root_unlock_time=60 (o mayor)"
SCRIPT_NAME="$(basename "$0")"
BLOCK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="/etc/security/hardening_backups"
FAILLOCK_CONF="/etc/security/faillock.conf"
ROOT_UNLOCK_TIME="60"
DRY_RUN=0
LOG_SUBDIR="exec"

if [[ ${1:-} == "--dry-run" || ${1:-} == "-n" ]]; then
  DRY_RUN=1
  LOG_SUBDIR="audit"
fi

LOG_DIR="${BLOCK_DIR}/Log/${LOG_SUBDIR}"
LOG_FILE="${LOG_DIR}/${ITEM_ID}.log"

mkdir -p "$LOG_DIR" "$BACKUP_DIR"
: > "$LOG_FILE"

log() {
  printf '[%s] %s\n' "$(date '+%F %T')" "$*" | tee -a "$LOG_FILE"
}
run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[DRY-RUN] $*"
  else
    log "[EXEC]   $*"
    eval "$@"
  fi
}
ensure_root() {
  [[ $EUID -eq 0 ]] || { log "ERROR: Este script debe ejecutarse como root."; exit 1; }
}

main() {
  ensure_root
  log "=== Remediación ${ITEM_ID}: ${ITEM_DESC} ==="

  if [[ ! -f "$FAILLOCK_CONF" ]]; then
    log "Archivo $FAILLOCK_CONF no existe. Creando..."
    run "touch '$FAILLOCK_CONF'"
  fi

  if grep -Eq '^\s*(even_deny_root|root_unlock_time\s*=\s*[6-9][0-9]|[1-9][0-9]{2,})\b' "$FAILLOCK_CONF"; then
    log "[OK] El archivo ya contiene configuración válida (even_deny_root o root_unlock_time >= 60)."
    log "== Remediación ${ITEM_ID}: ${ITEM_DESC} completada =="
    exit 0
  fi

  BACKUP_FILE="${BACKUP_DIR}/faillock.conf.$(date +%Y%m%d-%H%M%S)"
  run "cp --preserve=mode,ownership,timestamps '$FAILLOCK_CONF' '$BACKUP_FILE'"
  log "Backup creado: $BACKUP_FILE"

  run "echo >> '$FAILLOCK_CONF'"
  run "echo '# Añadido por $SCRIPT_NAME para cumplimiento $ITEM_ID' >> '$FAILLOCK_CONF'"
  run "echo 'even_deny_root' >> '$FAILLOCK_CONF'"
  run "echo 'root_unlock_time = $ROOT_UNLOCK_TIME' >> '$FAILLOCK_CONF'"
  log "[OK] Se añadieron 'even_deny_root' y 'root_unlock_time = $ROOT_UNLOCK_TIME' a $FAILLOCK_CONF"

  log "[SUCCESS] ${ITEM_ID} aplicado"
  log "== Remediación ${ITEM_ID}: ${ITEM_DESC} completada =="
  exit 0
}

main "$@"
