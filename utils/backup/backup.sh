#!/bin/bash

SCRIPT_DIRECTORY=`( cd -P $(dirname $0); pwd)`

# On inclut la bibliothèque shflags pour la gestion des options
. ${SCRIPT_DIRECTORY}/../shflags

# Définition des scripts à executer
mysql_backup_script="${SCRIPT_DIRECTORY}/mysqlbackup.sh"
postgres_backup_script="${SCRIPT_DIRECTORY}/psqlbackup.sh"

# Définition des options
DEFINE_boolean 'mysql' false 'activer mode mysql' 'm'
DEFINE_boolean 'postgres' false 'activer mode postgresql' 'p'

# Récupération des options
FLAGS "$@" || exit 1
eval set -- "${FLAGS_ARGV}"

# On défini une valeur de sortie par défaut
exit_value=0

if [ ${FLAGS_mysql} -eq ${FLAGS_TRUE} ]; then
    # On sauvegarde MySQL
    ${mysql_backup_script}
    if [ $? -ne 0 ]; then
        exit_value=1
    fi
fi

if [ ${FLAGS_postgres} -eq ${FLAGS_TRUE} ]; then
    # On sauvegarde PostgreSQL
    ${postgres_backup_script}
    if [ $? -ne 0 ]; then
        exit_value=2
    fi
fi

exit ${exit_value}
