#!/bin/bash

#
# ./remove_sd.sh --website test.mon-site.fr [--help]
#
# Sortie possible :
# - 0  : OK
# - 1  : Binaire manquant
# - 2  : Mauvaises options
# - 3  : Mauvais formatage du nom de domaine
# - 4  : Utilisateur non trouvé
# - 5  : Nom d'utilisateur inexistant
# - 6  : Répertoire utilisateur manquant
# - 7  : Erreur lors de la suppression du répertoire du sous-domaine
# - 8  : Répertoire du sous-domaine manquant
# - 9  : Erreur lors de la suppression de la base de données

SCRIPT_DIRECTORY=`( cd -P $(dirname $0); pwd)`

MYSQL_BIN=`which mysql`
MYSQL_PASS=`cat /root/.pdb`


#
# Ecrit une chaine sur la sortie d'erreur
#
function echoerr()
{
    echo "$@" 1>&2
}


# Vérification des binaires
if [ "${MYSQL_BIN}" = "" ]; then
    echoerr "mysql non trouve !"
    exit 1
fi


# On inclut le super script shflags :-)
. ${SCRIPT_DIRECTORY}/shflags

# Définition des options
DEFINE_string "website" "" "L'adresse du site internet" "w"

# Récupération des options
FLAGS "$@" || exit 2
eval set -- "${FLAGS_ARGV}"

# Vérification des options
# - le site internet doit contenir : [a-z0-9\._-]
echo "${FLAGS_website}" | grep -E -e "[^a-z0-9\._-]" > /dev/null
if [ $? -eq 0 ] || [ "${FLAGS_website}" = "" ]; then
    echoerr "Le nom du site internet ne doit etre compose que des caracteres suivants : [a-z0-9\._-]"
    exit 3
fi

#
# Récupération du nom d'utilisateur et du sd
#
base_website=`echo "${FLAGS_website}" | sed 's/\(.*\)\.\(.*\)\.\(.*\)$/\2.\3/'`
sd_website=`echo "${FLAGS_website}" | sed 's/\(.*\)\.\(.*\)\.\(.*\)$/\1/'`
username=`cat /etc/apache2/sites-available/0_${base_website} | grep 'DocumentRoot' | sed 's/\(.*\)\/home\/\(.*\)\/\(.*\)/\2/'`
if [ "${username}" = "" ]; then
    echoerr "Impossible de recuperer le nom d'utilisateur"
    exit 4
fi

#
# On vérifie que le nom d'utilisateur existe et que son home existe
#
cat /etc/shadow | grep "${username}:" > /dev/null || (echoerr "L'utilisateur ${username} n'existe pas"; exit 5)
if [ ! -d /home/${username} ]; then
    echoerr "Le repertoire utilisateur n'existe pas"
    exit 6
fi

#
# Suppression du répertoire
#
if [ -d /home/${username}/sd/${sd_website} ]; then
    rm -fr /home/${username}/sd/${sd_website}
    if [ "$?" != "0" ]; then
        echoerr "Erreur lors de la suppression du répertoire du sous-domaine"
        exit 7
    fi
else
    echoerr "Le repertoire du sous-domaine n'existe pas"
    exit 8
fi

#
# Suppression de la base de données associée
#
${MYSQL_BIN} -u root -p${MYSQL_PASS} -e "DROP DATABASE IF EXISTS ${username}_${sd_website};"
if [ "$?" != "0" ]; then
    echoerr "Suppression de la base de donnees echouee !"
    exit 9
fi

exit 0
