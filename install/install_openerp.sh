#!/bin/bash

if [ -z ${install_manage_by_high_level} ]; then
    SCRIPT_DIRECTORY=`( cd -P $(dirname $0); pwd)`
    
    # On inclut les fonctions de bases
    . ${SCRIPT_DIRECTORY}/install_lib.sh
fi

# Vérification des droits utilisateur
is_root

# Création de l'utilisateur openerp
createUser "openerp"

# Installation de PostgreSQL


addInEndMessage "OpenERP n'a pas d'installation standard\n#   Demerdez-vous !!!"

if [ -z ${install_manage_by_high_level} ]; then
    # Parce que c'est toujours utile, on fait un updatedb
    updatedb
    
    # On quitte l'installation
    printEndMessage
fi
