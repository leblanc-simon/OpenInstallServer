#!/bin/bash

log "Ajout du site ${website}" 1

add_site_script="${SCRIPT_DIRECTORY}/../add_site.sh"

if [ "${mysql}" = "0" ]; then
    ${add_site_script} --website "${website}" --password "${password}" --user "${user}" --quota "${quota}" --nomysql 2>&1
else
    ${add_site_script} --website "${website}" --password "${password}" --user "${user}" --quota "${quota}" --mysql 2>&1
fi

if [ $? -ne 0 ]; then
  log "Impossible d'ajout du site ${website}" 1
  exit 11
fi

log "Ajout du site ${website} : OK" 1
exit 0
