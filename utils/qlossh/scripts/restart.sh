#!/bin/bash

# On prepare les variables
if [ "${service}" = "apache2" ]; then
  service_name="Apache"
elif [ "${service}" = "mysql" ]; then
  service_name="MySQL"
elif [ "${service}" = "proftpd" ]; then
  service_name="ProFTPd"
else
  log "Erreur : Aucun service correspondant" 1
  exit 10
fi

log "Redemarrage du service ${service_name}" 1

service ${service} restart 2>&1
if [ $? -ne 0 ]; then
  log "Impossible de redemarrer ${service_name}" 1
  exit 11
fi

log "Redemarrage du service ${service_name} : OK" 1
exit 0
