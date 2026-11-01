#!/usr/bin/env bash
# Runs the workbook tests and saves REAL output to evidence/raw/ (git-ignored by default).
# Usage (from repo root):  bash scripts/run-tests.sh <phase>
#   phases: baseline | forward | reverse | ssh-b | icmp-fail | icmp-recover
# Each phase runs the command from the correct host through your SSH config and
# stores the output with a timestamp so you can screenshot or paste it into the report.
set -uo pipefail

PHASE="${1:-}"
OUTDIR="evidence/raw"
mkdir -p "${OUTDIR}"
STAMP="$(date +%Y%m%d-%H%M%S)"
LOG="${OUTDIR}/${STAMP}-${PHASE}.txt"

run() { # run <label> <command...>
  echo "### $1" | tee -a "${LOG}"
  shift
  echo "\$ $*" | tee -a "${LOG}"
  "$@" 2>&1 | tee -a "${LOG}"
  echo "" | tee -a "${LOG}"
}

case "${PHASE}" in
  baseline)
    # Test 01: before peering, App-A cannot reach App-B (expect 100% packet loss)
    run "Test 01 / Baseline (App-A -> App-B, expect NO replies)" \
      ssh ewb-app-a 'hostname; hostname -I; ping -c 4 -W 2 10.20.1.10'
    ;;
  forward)
    # Test 02: App-A -> App-B after routes (expect 4 replies, 0% loss)
    run "Test 02 / Forward path (App-A -> App-B)" \
      ssh ewb-app-a 'hostname; hostname -I; ping -c 4 10.20.1.10'
    ;;
  reverse)
    # Test 03: App-B -> App-A after routes (expect 4 replies, 0% loss)
    run "Test 03 / Reverse path (App-B -> App-A)" \
      ssh ewb-app-b 'hostname; hostname -I; ping -c 4 10.10.2.10'
    ;;
  ssh-b)
    # Test 04: private SSH to App-B through the bastion
    run "Test 04 / Private SSH to App-B via ProxyJump" \
      ssh ewb-app-b 'echo "Connected to: $(hostname)"; hostname -I; whoami'
    ;;
  icmp-fail)
    # Controlled failure: run AFTER setting enable_app_b_icmp_rule=false and applying
    run "Controlled failure (App-B ICMP rule removed, expect NO replies)" \
      ssh ewb-app-a 'hostname; ping -c 4 -W 2 10.20.1.10'
    ;;
  icmp-recover)
    # Recovery: run AFTER setting enable_app_b_icmp_rule=true and applying
    run "Recovery (App-B ICMP rule restored, expect 4 replies)" \
      ssh ewb-app-a 'hostname; ping -c 4 10.20.1.10'
    ;;
  *)
    echo "Usage: bash scripts/run-tests.sh baseline|forward|reverse|ssh-b|icmp-fail|icmp-recover"
    exit 1
    ;;
esac

echo "Saved to ${LOG}"
