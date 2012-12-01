#!/bin/bash
HNAME="$1"
KEYSCANBIN=`which ssh-keyscan`
RSYNCBIN=`which rsync`
SUDOBIN=`which sudo`

KNOWNHOSTFILE="/home/backuppc/.ssh/known_hosts"
BPCHOSTFILE="/etc/backuppc/hosts"
BPCCONF="/etc/backuppc/"
CONFFILE="/root/travaux/utils/backup/${HNAME}.pl"
USERBACKUP="backuppc"

#Declaration des différentes erreurs
ERR[1]="Machine ${HNAME} injoignable"
ERR[2]="Erreur lors de l'ecriture dans le fichier ${KNOWNHOSTFILE}"
ERR[3]="Erreur lors de l'ecriture dans le fichier ${BPCHOSTFILE}"
ERR[4]="Erreur lors du rappatriement du fichier ${CONFFILE} via rsync"

errortest () {
	if [ $? -ne "0" ]
	then
	        echo "erreur lors de l'execution du script"
		echo ${ERR[$1]}
		exit $?
	fi
		}

# test si le nombre de parametres differents de de 1
if [ $# -ne "1" ]
then 
	echo "Il ne faut quun seul argument. Usage : ./bpcaddhost hostname"
	exit 1
fi

#Recup de la fingerprint
BPCHOST="${HNAME}	0	root"
HOSTFPRINT=`${KEYSCANBIN} -H ${HNAME}`
errortest 1 

#On valide avec l'utilisateur avant d'ecrire dans les fichiers.
echo "voulez vous rajouter l'hote \"${HNAME}\" a backuppc ? O/n"
read REPONSE

#Ecriture dans le fichier
if [ "${REPONSE}" == "o" -o "${REPONSE}" == "O" ]
then
	echo ${HOSTFPRINT} >> ${KNOWNHOSTFILE}
	errortest 2
	echo ${BPCHOST} >> ${BPCHOSTFILE}
	errortest 3
else
	echo "fin du script"
	exit
fi

#Copie du fichier de configuration de l'hôte via rsync
${SUDOBIN} -u ${USERBACKUP} ${RSYNCBIN} ${HNAME}:${CONFFILE} ${BPCCONF}
errortest 4
