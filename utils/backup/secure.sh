#!/bin/bash
case "$SSH_ORIGINAL_COMMAND" in
  *\&*)
        echo "Rejected"
        exit 1
    ;;
  *\(*)
        echo "Rejected"
        exit 1
    ;;
  *\{*)
        echo "Rejected"
        exit 1
    ;;
  *\;*)
        echo "Rejected"
        exit 1
    ;;
  *\<*)
        echo "Rejected"
        exit 1
    ;;
  *\`*)
        echo "Rejected"
        exit 1
    ;;
  *\|*)
        echo "Rejected"
        exit 1
    ;;
  /usr/bin/rsync*)
    bash -c "$SSH_ORIGINAL_COMMAND"
    ;;
  rsync*)
    bash -c "$SSH_ORIGINAL_COMMAND"
    ;;
  /root/travaux/utils/backup/backup.sh*)
        bash -c "$SSH_ORIGINAL_COMMAND"
    ;;
  *)
        echo "Rejected"
        exit 1
    ;;
esac
