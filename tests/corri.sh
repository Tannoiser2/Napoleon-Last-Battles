#!/bin/bash
# Uso: tests/corri.sh script.gd [argomenti]  (aggiorna le classi e lancia lo script headless)
G=${GODOT:-godot}
cd "$(dirname "$0")/.."
timeout 300 $G --headless --path . --import > /tmp/import.log 2>&1
S=$1; shift
timeout ${TEMPO:-600} $G --headless --path . -s res://tests/$S -- "$@"
