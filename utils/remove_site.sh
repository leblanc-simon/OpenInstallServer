#!/bin/bash

#
# ./remove_site.sh --website mon-site.fr [--help]
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
MYSQL_BIN=`which mysql`
MYSQLDUMP_BIN=`which mysqldump`
MYSQL_PASS=`cat /root/.pdb`


#
# Ecrit une chaine sur la sortie d'erreur
#
function echoerr()
{
    echo "$@" 1>&2
}


# Vérification des binaires
if [ "${MYSQL_BIN}" = "" ] || [ "${MYSQLDUMP_BIN}" = "" ] || [ "${DELUSER_BIN}" = "" ]; then
    echoerr "mysql, mysqldump ou deluser non trouve !"
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
# Sauvegarde de la base de données associée (on ne sait jamais vu qu'on met un outil d'administration dans les mains de n'importe qui :-))
#
database_exist=`${MYSQL_BIN} -u root -p${MYSQL_PASS} -s -N -e "SELECT COUNT(*) FROM mysql.db WHERE Db = '${username}' AND User = '${username}';"`
if [ "${database_exist}" = "1" ]; then
    ${MYSQLDUMP_BIN} -u root -p${MYSQL_PASS} --opt ${username} > "/home/${username}/dump_before_delete_${username}.sql"
    if [ "$?" != "0" ]; then
        echoerr "Backup de la base de donnees echouee !"
        exit 7
    fi
    
    chown ${username}:${username} "/home/${username}/dump_before_delete_${username}.sql"
    if [ "$?" != "0" ]; then
        echoerr "Affectation des droits sur le backup de la base de donnees echouee !"
        exit 8
    fi
fi

#
# Suppression de la base de données associée
#
${MYSQL_BIN} -u root -p${MYSQL_PASS} -e "DROP DATABASE IF EXISTS ${username};"
if [ "$?" != "0" ]; then
    echoerr "Suppression de la base de donnees echouee !"
    exit 9
fi

# On vérifie que l'utilisateur mysql existe
user_exist=`${MYSQL_BIN} -u root -p${MYSQL_PASS} -s -N -e "SELECT COUNT(*) FROM mysql.user WHERE User = '${username}';"`
if [ "${user_exist}" = "1" ]; then
    # On supprime l'utilisateur MySQL
    ${MYSQL_BIN} -u root -p${MYSQL_PASS} -e "DROP USER ${username}@localhost;"
    if [ "$?" != "0" ]; then
        echoerr "Suppression de l'utilisateur mysql echouee !"
        exit 11
    fi
fi

# On supprime l'utilisateur Unix
deluser --backup --backup-to /home --remove-home ${username}
if [ "$?" != "0" ]; then
    echoerr "Erreur lors de la suppression de l'utilisateur Unix"
    exit 12
fi

# On supprime les fichiers de configuration apache
# - Désactivation des sites (pas de vérification car pas important)
a2dissite 0_${FLAGS_website}
a2dissite 1_${FLAGS_website}
# - Suppression des fichiers de configuration
if [ -f /etc/apache2/sites-available/0_${FLAGS_website} ]; then
    rm -f /etc/apache2/sites-available/0_${FLAGS_website}
    if [ "$?" != "0" ]; then
        echoerr "Erreur lors de la suppression du fichier /etc/apache2/sites-available/0_${FLAGS_website}"
        exit 13
    fi
fi
if [ -f /etc/apache2/sites-available/1_${FLAGS_website} ]; then
    rm -f /etc/apache2/sites-available/1_${FLAGS_website}
    if [ "$?" != "0" ]; then
        echoerr "Erreur lors de la suppression du fichier /etc/apache2/sites-available/1_${FLAGS_website}"
        exit 14
    fi
fi


echo "############################################"
echo "# "
echo "# Le domaine ${FLAGS_website} a ete supprime :"
echo "# "
echo "# - un backup se trouve dans /home"
echo "# "
echo "# PENSEZ A REDEMARRER APACHE !!!"
echo "# "
echo "############################################"

exit 0
