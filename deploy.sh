#!/bin/bash

SCRIPT_DIRECTORY=`( cd -P $(dirname $0); pwd)`

include_files=`ls ${SCRIPT_DIRECTORY}/lib | sort`

for include_file in ${include_files}; do
    . "${SCRIPT_DIRECTORY}/lib/${include_file}"
done


################################################################################
#
# Program
#
################################################################################

logInfo "Demarrage du deploiement"


# On doit être root
is_root

# On se met à jour soit-même
logInfo "Mise a jour du script de deploiement"
update_me
if [ $? -eq 0 ]; then
    logInfo "Mise a jour du script de deploiement : OK"
fi

# On met à jour les clés SSH
logInfo "Mise a jour des cles SSH"
update_ssh
if [ $? -eq 0 ]; then
    logInfo "Mise a jour des cles SSH : OK"
fi

# On met à jour les fichiers init.d
logInfo "Mise a jour des fichiers init.d"
update_initd
if [ $? -eq 0 ]; then
    logInfo "Mise a jour des fichiers init.d : OK"
fi

# On met à jour les fichier de config utilisateur
logInfo "Mise a jour des fichiers de configuration utilisateur"
update_dotfiles
if [ $? -eq 0 ]; then
    logInfo "Mise a jour des fichiers de configuration utilisateur : OK"
fi

# On met à jour les configurations logiciel
# - iptables
logInfo "Mise a jour des fichiers de configuration iptables"
update_iptables
if [ $? -eq 0 ]; then
    logInfo "Mise a jour des fichiers de configuration iptables : OK"
    
    # Redémarrage d'iptables après la configuration
    logInfo "Redemarrage d'iptables"
    /etc/init.d/iptables.sh restart
    if [ $? -eq 0 ]; then
        logInfo "Redemarrage d'iptables : OK"
    else
        logError "Erreur lors du redemarrage d'iptables"
    fi
fi

# - Fail2ban
logInfo "Mise a jour des fichiers de configuration fail2ban"
update_fail2ban
if [ $? -eq 0 ]; then
    logInfo "Mise a jour des fichiers de configuration fail2ban : OK"
fi

# - Logwatch
logInfo "Mise a jour des fichiers de configuration logwatch"
update_logwatch
if [ $? -eq 0 ]; then
    logInfo "Mise a jour des fichiers de configuration logwatch : OK"
fi

# - Proftpd
logInfo "Mise a jour des fichiers de configuration proftpd"
update_proftpd
if [ $? -eq 0 ]; then
    logInfo "Mise a jour des fichiers de configuration proftpd : OK"
fi

# - cron
logInfo "Mise a jour des fichiers de cron"
update_cron
if [ $? -eq 0 ]; then
    logInfo "Mise a jour des fichiers de cron : OK"
fi

# - SNMP
logInfo "Mise a jour des fichiers de configuration de SNMP"
update_snmp
if [ $? -eq 0 ]; then
    logInfo "Mise a jour des fichiers de configuration de SNMP : OK"
fi

# Configuration spécifique au web
isNotWeb
if [ $? -eq 1 ]; then
    # - Apache
    logInfo "Mise a jour des fichiers de configuration apache"
    update_apache
    if [ $? -eq 0 ]; then
        logInfo "Mise a jour des fichiers de configuration apache : OK"
    fi
    
    # - php.ini
    logInfo "Mise a jour du fichier de configuration php"
    update_php
    if [ $? -eq 0 ]; then
        logInfo "Mise a jour du fichier de configuration php : OK"
    fi
    
    # - phpmyadmin
    logInfo "Mise a jour des fichiers de configuration phpmyadmin"
    update_phpmyadmin
    if [ $? -eq 0 ]; then
        logInfo "Mise a jour des fichiers de configuration phpmyadmin : OK"
    fi
    
    # - suphp
    logInfo "Mise a jour des fichiers de configuration suphp"
    update_suphp
    if [ $? -eq 0 ]; then
        logInfo "Mise a jour des fichiers de configuration suphp : OK"
    fi
fi


logInfo "Fin du deploiement"

exit 0
