#!/bin/bash

log "Modification des quotas de ${user}" 1

fix_quota_script="${SCRIPT_DIRECTORY}/../fix_quota.sh"


${fix_quota_script} --user "${user}" --quota "${quota}" 2>&1

if [ $? -ne 0 ]; then
  log "Impossible de modifier le quota de ${user}" 1
  exit 11
fi

log "Modification des quotas de ${user} : OK" 1
exit 0
