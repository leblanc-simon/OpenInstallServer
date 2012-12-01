#!/bin/bash

SCRIPT_DIRECTORY=`( cd -P $(dirname $0); pwd)`

# On inclut les fonctions de bases
. ${SCRIPT_DIRECTORY}/install_lib.sh

# On inclut le super script shflags :-)
. ${SCRIPT_DIRECTORY}/../utils/shflags

# Définition des options
DEFINE_boolean "web" false "Installe la partie web" "w"
DEFINE_boolean "openerp" false "Installe la partie OpenERP" "o"

# Récupération des options
FLAGS "$@" || exit 2
eval set -- "${FLAGS_ARGV}"

# On indique que c'est une installation géré par l'installateur haut niveau
install_manage_by_high_level="yes"

# Vérification des droits utilisateur
is_root

# On pose les questions en début de script
# - question de base
getHostname

# - question pour la partie web
if [ ${FLAGS_web} -eq ${FLAGS_TRUE} ]; then
    getMySQLPasswd
fi

# - question pour la partie OpenERP
if [ ${FLAGS_openerp} -eq ${FLAGS_TRUE} ]; then
    getDatasPostgres
fi


# On effectue les installations de base du serveur
. ${SCRIPT_DIRECTORY}/install_base.sh

backup_options=""

# Installation de la partie web si besoin
if [ ${FLAGS_web} -eq ${FLAGS_TRUE} ]; then
    backup_options="${backup_options}web;"
    . ${SCRIPT_DIRECTORY}/install_web.sh
fi

# Installation de la partie OpenERP si besoin
if [ ${FLAGS_openerp} -eq ${FLAGS_TRUE} ]; then
    backup_options="${backup_options}openerp;"
    . ${SCRIPT_DIRECTORY}/install_openerp.sh
fi

# On génère le fichier de backup
buildBackupFile "${backup_options}"

# Parce que c'est toujours utile, on fait un updatedb
updatedb
    
# On quitte l'installation
printEndMessage
