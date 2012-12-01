#!/bin/bash

log "Suppression du site ${website}" 1

remove_site_script="${SCRIPT_DIRECTORY}/../remove_site.sh"

${remove_site_script} --website "${website}" 2>&1

if [ $? -ne 0 ]; then
  log "Impossible de supprimer le site ${website}" 1
  exit 11
fi

log "Suppression du site ${website} : OK" 1
exit 0
