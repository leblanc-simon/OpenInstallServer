#!/bin/bash

log "Suppression du sous-domaine ${website}" 1

remove_sd_script="${SCRIPT_DIRECTORY}/../remove_sd.sh"

${remove_sd_script} --website "${website}" 2>&1

if [ $? -ne 0 ]; then
  log "Impossible de supprimer le sous-domaine ${website}" 1
  exit 11
fi

log "Suppression du sous-domaine ${website} : OK" 1
exit 0
