#!/bin/bash

if [ -z ${install_manage_by_high_level} ]; then
    SCRIPT_DIRECTORY=`( cd -P $(dirname $0); pwd)`
    
    # On inclut les fonctions de bases
    . ${SCRIPT_DIRECTORY}/install_lib.sh
fi

# Vérification des droits utilisateur
is_root

# Mise à jour du hostname
getHostname
updateHostname

# Mise à jour de l'adresse mail
getMailAddress

# Mise à jour des adresses IP
getIpAddress

# Mise à jour des paquets
updateSystem

# Paramétrage des outils de base
parameterBase

# installation de base du serveur
installBase

# installation de fail2ban
installFail2ban

# installation de munin
installMunin

# installation de postfix
installPostfix

# installation de logwatch
installLogwatch

# installation de proftpd
installProftpd

# installation des éléments pour les quotas
installQuotas

# déplacement des fichiers de log
moveLog

if [ -z ${install_manage_by_high_level} ]; then
    # Parce que c'est toujours utile, on fait un updatedb
    updatedb
    
    # On quitte l'installation
    printEndMessage
fi
