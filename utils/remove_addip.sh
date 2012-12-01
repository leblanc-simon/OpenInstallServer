#!/bin/bash
# VARIABLES
IPTABLES_BIN="/sbin/iptables"
MAIL_TO=`cat /root/.techmail`
LOG_FTP="/var/log/xferlog"
SERVER=`hostname`
TIME_OPEN=6

# Recuperation des arguments
IP=${1}
PORT=${2}

# Fonction d'envoie de mail
# @param  String  Le message à envoyer
function send_email()
{
    local message=${1}
    echo "${message}" | mail -s "Modification iptables sur ${SERVER}" ${MAIL_TO}
}

# Verification des arguments
if [ -z "$(echo ${IP} | grep -E -e '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$')" ]; then
    echo "L'adresse IP n'est pas correcte"
    exit 1
fi
if [ -z "$(echo ${PORT} | grep "^[ [:digit:] ]*$")" ]; then
    echo "Le port n'est pas correct"
    exit 1
fi


# On lance le programme

# Récupération du numero de la regle à supprimer
NUM=`${IPTABLES_BIN} -L -v -n --line-numbers | grep "${IP}" | grep "tcp dpt:${PORT}" | grep "ACCEPT" | awk '{print \$1;}'`

# Si tout s'est bien déroulé et que le numero de la regle est un entier
# alors on continue, sinon on quitte le programme
if [ $? -eq 0 ] && [ "$(echo ${NUM} | grep "^[ [:digit:] ]*$")" ]; then
    # Suppression de la regle
    echo "On supprime la regle"
    ${IPTABLES_BIN} -D INPUT ${NUM}
    
    # Si tout s'est bien déroulé, on continue
    if [ $? -eq 0 ]; then
        echo "La regle a bien ete supprimee"
        
        # Si ce n'est pas un FTP, on quitte et on envoie un mail
        if [ "${PORT}" != "21" ]; then
            send_email "La regle '${IP}:${PORT}' a bien ete supprimee"
            exit 0
        fi
        
        # On regarde ce qui a ete fait si l'ouverture etait un FTP
        LOCALE=`locale | grep LC_TIME`
        DEGIN_DATE=`date +%d --date="${TIME_OPEN} hours ago"`
        END_DATE=`date +%d`
        
        if [ "${DEGIN_DATE}" = "${END_DATE}" ]; then
            DATE=`export LC_TIME=en_EN.utf8 && date +"%a %h %e" --date="${TIME_OPEN} hours ago" && export LC_TIME=${LOCALE}`
            REGEXP="(${DATE})"
        else
            DATE1=`export LC_TIME=en_EN.utf8 && date +"%a %h %e" --date="${TIME_OPEN} hours ago" && export LC_TIME=${LOCALE}`
            DATE2=`export LC_TIME=en_EN.utf8 && date +"%a %h %e" && export LC_TIME=${LOCALE}`
            REGEXP="(${DATE1}|${DATE2})"
        fi
        
        # on récupère les logs FTP
        LOG=`cat ${LOG_FTP} | grep "${IP}" | grep -E -e "${REGEXP}"`
        
        # On envoie le resultat par mail
        send_email "La regle '${IP}:${PORT}' a bien ete supprimee\n\n${LOG}"
    else
        echo "La regle n'a pas ete supprimee"
        send_email "La regle '${IP}:${PORT}' n'a pas ete supprimee !"
        exit 2
    fi
else
    echo "pas de regle"
    exit 3
fi

exit 0
