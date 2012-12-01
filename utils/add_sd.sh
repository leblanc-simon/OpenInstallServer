#!/bin/bash

#
# ./add_sd.sh --website test.mon-site.fr [--nomysql] [--help]
#
# Sortie possible :
# - 0  : OK
# - 1  : Binaire manquant
# - 2  : Mauvaises options
# - 3  : Mauvais formatage du nom de domaine
# - 4  : Utilisateur non trouvé
# - 5  : Nom d'utilisateur inexistant
# - 6  : Répertoire utilisateur manquant
# - 7  : Erreur lors de la création de l'utilisateur MySQL
# - 8  : Erreur lors de l'affectation des droits généraux de l'utilisateur MySQL
# - 9  : Erreur lors de la création de la base de données
# - 10 : Erreur lors de l'affectation des droits sur la base de données de l'utilisateur MySQL

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
DEFINE_boolean "mysql" true "Indique si l'on utilise une base de donnees" "m"

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
# Création du répertoire et affectation des droits
#
mkdir -p /home/${username}/sd/${sd_website}/www
chown ${username}:${username} /home/${username}/sd
chown -R ${username}:${username} /home/${username}/sd/${sd_website}
chmod 755 -R /home/${username}/sd/${sd_website}


#
# Ajout de la base MySQL
#
if [ ${FLAGS_mysql} -eq ${FLAGS_TRUE} ]; then
    # On vérifie que l'utilisateur mysql existe
    user_exist=`${MYSQL_BIN} -u root -p${MYSQL_PASS} -s -N -e "SELECT COUNT(*) FROM mysql.user WHERE User = '${username}';"`
    if [ "${user_exist}" = 0 ]; then
        # On génére un mot de passe
        password=`head -c 10 /dev/urandom | perl -e 'use MIME::Base64 qw(encode_base64);print encode_base64(<>);' | sed "s/\(.\{8\}\).*/\1/"`
        
        # Création de l'utilisateur MySQL
        ${MYSQL_BIN} -u root -p${MYSQL_PASS} -e "CREATE USER '${username}'@'localhost' IDENTIFIED BY '${password}';"
        if [ "$?" != "0" ]; then
            echoerr "Creation de l'utilisateur MySQL '${username}' echouee  !"
            exit 7
        fi
      
        # Mise en place des droits utilisateurs
        ${MYSQL_BIN} -u root -p${MYSQL_PASS} -e "GRANT USAGE ON * . * TO '${username}'@'localhost' IDENTIFIED BY '${password}' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0 ;"
        if [ "$?" != "0" ]; then
            echoerr "Affectation des droits utilisateur MySQL echouee !"
            exit 8
        fi
    fi
  
    # Création de la base de donnees
    ${MYSQL_BIN} -u root -p${MYSQL_PASS} -e "CREATE DATABASE IF NOT EXISTS ${username}_${sd_website};"
    if [ "$?" != "0" ]; then
        echoerr "Creation de la base de donnees echouee !"
        exit 9
    fi
  
    # Affection des droits utilisateur sur la base de donnees
    ${MYSQL_BIN} -u root -p${MYSQL_PASS} -e "GRANT ALL PRIVILEGES ON ${username}_${sd_website} . * TO '${username}'@'localhost';"
    if [ "$?" != "0" ]; then
        echoerr "Affection des droits utilisateur sur la base de donnees echouee !"
        exit 10
    fi
fi


echo "############################################"
echo "# "
echo "# Le sous-domaine ${FLAGS_website} a ete cree :"
echo "# "
echo "# - repertoire : /home/${username}/sd/${sd_website}"
if [ ${FLAGS_mysql} -eq ${FLAGS_TRUE} ]; then
    echo "# - base de donnees : ${username}_${sd_website}"
    echo "# - login mysql : ${username}"
    if [ "${user_exist}" = 0 ]; then
        echo "# - pass mysql : ${password}"
    else
        echo "# - pass mysql : identique a precedemment"
    fi
else
    echo "# - aucune base de donnees"
fi
echo "# "
echo "############################################"

exit 0
