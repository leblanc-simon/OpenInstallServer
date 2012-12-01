#!/bin/bash

#
# ./remove_ftp.sh --user "mon_user" [--help]
#
# Sortie possible :
# - 0  : OK
# - 1  : Binaire manquant
# - 2  : Mauvaises options
# - 3  : Mauvais formatage du nom de domaine
# - 4  : Utilisateur non trouvé
# - 5  : Nom d'utilisateur inexistant
# - 6  : Répertoire utilisateur manquant
# - 7  : Erreur lors du backup de la base de données
# - 8  : Erreur lors de l'affectation des droits au backup de la base de données
# - 9  : Erreur lors de la suppression de la base de données
# - 10 : (DEPRECATED) Erreur lors de la suppression des droits MySQL
# - 11 : Erreur lors de la suppression de l'utilisateur MySQL
# - 12 : Erreur lors de la suppression de l'utilisateur Unix
# - 13 : Erreur lors de la suppression du fichier de configuration apache (primaire)
# - 14 : Erreur lors de la suppression du fichier de configuration apache (secondaire)

SCRIPT_DIRECTORY=`( cd -P $(dirname $0); pwd)`

DELUSER_BIN=`which deluser`


#
# Ecrit une chaine sur la sortie d'erreur
#
function echoerr()
{
    echo "$@" 1>&2
}


# Vérification des binaires
if [ "${DELUSER_BIN}" = "" ]; then
    echoerr "deluser non trouve !"
    exit 1
fi


# On inclut le super script shflags :-)
. ${SCRIPT_DIRECTORY}/shflags

# Définition des options
DEFINE_string "user" "" "Le nom d'utilisateur a utiliser" "u"

# Récupération des options
FLAGS "$@" || exit 2
eval set -- "${FLAGS_ARGV}"

# Vérification des options
# - le nom d'utilisateur ne peut pas etre null
if [ "${FLAGS_user}" = "" ]; then
    echo "Le nom d'utilisateur ne peut pas etre vide"
    exit 3
fi

# - le nom d'utilisateur doit etre correct
echo "${FLAGS_user}" | grep -E -e "[^a-z]" > /dev/null
if [ $? -eq 0 ]; then
    echoerr "Le nom d'utilisateur ne doit etre compose que des caracteres suivants : [a-z]"
    exit 4
fi

#
# On vérifie que le nom d'utilisateur existe et que son home existe
#
cat /etc/shadow | grep "${FLAGS_user}:" > /dev/null || (echoerr "L'utilisateur ${FLAGS_user} n'existe pas"; exit 5)
if [ ! -d /home/${FLAGS_user} ]; then
    echoerr "Le repertoire utilisateur n'existe pas"
    exit 5
fi

# On supprime l'utilisateur Unix
deluser --backup --backup-to /home --remove-home ${FLAGS_user}
if [ "$?" != "0" ]; then
    echoerr "Erreur lors de la suppression de l'utilisateur Unix"
    exit 12
fi


echo "############################################"
echo "# "
echo "# L'utilisateur ${FLAGS_user} a ete supprime :"
echo "# "
echo "# - un backup se trouve dans /home"
echo "# "
echo "############################################"

exit 0
