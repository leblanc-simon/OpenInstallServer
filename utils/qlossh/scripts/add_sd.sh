#!/bin/bash

log "Ajout du sous-domaine ${website}" 1

add_sd_script="${SCRIPT_DIRECTORY}/../add_sd.sh"

if [ "${mysql}" = "0" ]; then
    ${add_sd_script} --website "${website}" --nomysql 2>&1
else
    ${add_sd_script} --website "${website}" --mysql 2>&1
fi

if [ $? -ne 0 ]; then
  log "Impossible d'ajout du sous-domaine ${website}" 1
  exit 11
fi

log "Ajout du sous-domaine ${website} : OK" 1
exit 0
