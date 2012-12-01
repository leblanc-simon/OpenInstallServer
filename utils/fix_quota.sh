#!/bin/bash

#
# ./fix_quota.sh --user mon_user --quota taille [--help]
#
# Sortie possible :
# - 0  : OK
# - 1  : Binaire manquant
# - 2  : Mauvaises options
# - 3  : Nom d'utilisateur inexistant
# - 4  : Erreur lors de l'affectation des quotas

SCRIPT_DIRECTORY=`( cd -P $(dirname $0); pwd)`

SETQUOTA_BIN=`which setquota`


#
# Ecrit une chaine sur la sortie d'erreur
#
function echoerr()
{
    echo "$@" 1>&2
}


# Vérification des binaires
if [ "${SETQUOTA_BIN}" = "" ]; then
    echoerr "setquota non trouve !"
    exit 1
fi


# On inclut le super script shflags :-)
. ${SCRIPT_DIRECTORY}/shflags

# Définition des options
DEFINE_string "user" "" "Le nom d'utilisateur" "u"
DEFINE_integer "quota" 0 "Le quota affecte au compte en Mo" "q"

# Récupération des options
FLAGS "$@" || exit 2
eval set -- "${FLAGS_ARGV}"

#
# On vérifie que le nom d'utilisateur existe et que son home existe
#
cat /etc/shadow | grep "${FLAGS_user}:" > /dev/null || (echoerr "L'utilisateur ${username} n'existe pas"; exit 3)


#
# Affectation des quotas
#
if [ "${FLAGS_quota}" != "0" ]; then
    let "quotas=${FLAGS_quota}*1000"
    ${SETQUOTA_BIN} -u ${FLAGS_user} 0 ${quotas} 0 0 /home
    if [ "$?" != "0" ]; then
        echoerr "L'affectation des quotas a echoue !"
        exit 4
    fi
fi

echo "############################################"
echo "# "
if [ "${FLAGS_quota}" != "0" ]; then
    echo "# quota : ${FLAGS_quota} Mo"
else
    echo "# quota : non modifie"
fi
echo "# "
echo "############################################"

exit 0
