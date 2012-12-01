#!/bin/bash

SCRIPT_DIRECTORY=`( cd -P $(dirname $0); pwd)`
TODAY=`date +"%Y%m%d"`
LOG_FILENAME="${SCRIPT_DIRECTORY}/logs/secure_${TODAY}.log"

log(){
  actual_time=`date +"%Y-%m-%d:%T"`
  echo "${actual_time} $1" >> "${LOG_FILENAME}"
  if [ $# -eq 2 ]; then
    echo "$1"
  fi
}


case "$SSH_ORIGINAL_COMMAND" in
  *\&*)
    log "Rejected -> '&' : $SSH_ORIGINAL_COMMAND" 1
    ;;
  *\(*)
    log "Rejected -> '(' : $SSH_ORIGINAL_COMMAND" 1
    ;;
  *\{*)
    log "Rejected -> '{' : $SSH_ORIGINAL_COMMAND" 1
    ;;
  *\;*)
    log "Rejected -> ';' : $SSH_ORIGINAL_COMMAND" 1
    ;;
  *\<*)
    log "Rejected -> '<' : $SSH_ORIGINAL_COMMAND" 1
    ;;
  *\`*)
    log "Rejected -> '\`' : $SSH_ORIGINAL_COMMAND" 1
    ;;
  *\|*)
    log "Rejected -> '|' : $SSH_ORIGINAL_COMMAND" 1
    ;;
  ${SCRIPT_DIRECTORY}/exec.sh*)
    bash -c "$SSH_ORIGINAL_COMMAND"
    ;;
  *)
    log "Rejected -> '*' : $SSH_ORIGINAL_COMMAND" 1
    ;;
esac 

