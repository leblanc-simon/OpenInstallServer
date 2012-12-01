#!/bin/bash

if [ -z ${install_manage_by_high_level} ]; then
    SCRIPT_DIRECTORY=`( cd -P $(dirname $0); pwd)`
    
    # On inclut les fonctions de bases
    . ${SCRIPT_DIRECTORY}/install_lib.sh
fi

# Vérification des droits utilisateur
is_root

# installation de lamp
installLamp

# installation de phpmyadmin
installPhpMyAdmin

# installation de awstats
installAwstats

# déplacement des fichiers de MySQL
moveMySQLData

if [ -z ${install_manage_by_high_level} ]; then
    # Parce que c'est toujours utile, on fait un updatedb
    updatedb
    
    # On quitte l'installation
    printEndMessage
fi
