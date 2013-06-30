#!/bin/bash

#
# ./add_site.sh --website mon-site.fr --password "mon mot de passe" [--user mon_user] [--quota 500] [--nomysql] [--help]
#
# Sortie possible :
# - 0  : OK
# - 1  : Binaire manquant
# - 2  : Mauvaises options
# - 3  : Mauvais formatage du nom de domaine
# - 4  : Mauvais formatage du mot de passe
# - 5  : Mauvais formatage du nom d'utilisateur
# - 6  : Nom d'utilisateur déjà existant
# - 7  : Erreur lors de la création de l'utilisateur
# - 8  : Erreur lors de l'affectation des quotas
# - 9  : Erreur lors de la création de l'utilisateur MySQL
# - 10 : Erreur lors de l'affectation des droits généraux de l'utilisateur MySQL
# - 11 : Erreur lors de la création de la base de données
# - 12 : Erreur lors de l'affectation des droits sur la base de données de l'utilisateur MySQL


SCRIPT_DIRECTORY=`( cd -P $(dirname $0); pwd)`

ADDUSER_BIN=`which useradd`
SETQUOTA_BIN=`which setquota`
MYSQL_BIN=`which mysql`

MYSQL_PASS=`cat /root/.pdb`
APACHE_WWW_TPL="${SCRIPT_DIRECTORY}/template/www"
APACHE_SD_TPL="${SCRIPT_DIRECTORY}/template/sd"
AWSTATS_TPL="${SCRIPT_DIRECTORY}/template/awstats.conf"

#
# Ecrit une chaine sur la sortie d'erreur
#
function echoerr()
{
    echo "$@" 1>&2
}


# Vérification des binaires
if [ "${ADDUSER_BIN}" = "" ] || [ "${SETQUOTA_BIN}" = "" ] || [ "${MYSQL_BIN}" = "" ]; then
    echoerr "adduser, setquota ou mysql non trouve !"
    exit 1
fi

# On inclut le super script shflags :-)
. ${SCRIPT_DIRECTORY}/shflags

# Définition des options
DEFINE_string "website" "" "L'adresse du site internet" "w"
DEFINE_string "password" "" "Le mot de passe du compte" "p"
DEFINE_string "user" "" "Le nom d'utilisateur a utiliser" "u"
DEFINE_integer "quota" 500 "Le quota affecte au compte en Mo" "q"
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

# - le mot de passe ne peut pas etre null
if [ "${FLAGS_password}" = "" ]; then
    echo "Le mot de passe ne peut pas etre vide"
    exit 4
fi

# - le nom d'utilisateur doit etre correct
if [ "${FLAGS_user}" != "" ]; then
    echo "${FLAGS_user}" | grep -E -e "[^a-z]" > /dev/null
    if [ $? -eq 0 ]; then
        echoerr "Le nom d'utilisateur ne doit etre compose que des caracteres suivants : [a-z]"
        exit 5
    fi
fi

#
# Récupération du nom d'utilisateur
#
if [ "${FLAGS_user}" = "" ]; then
    FLAGS_user=`echo "${FLAGS_website}" | sed "s/[^a-z]//" | sed "s/\(.\{8\}\).*/\1/"`
fi

#
# Vérification du nom d'utilisateur
#
cat /etc/shadow | grep "${FLAGS_user}:" > /dev/null
if [ $? -eq 0 ]; then
    echoerr "Le nom d'utilisateur \"${FLAGS_user}\" existe deja"
    exit 6
fi

#
# Création de l'utilisateur
#
SALT=`head -c 10 /dev/urandom | perl -e 'use MIME::Base64 qw(encode_base64);print encode_base64(<>);' | sed "s/\(.\{2\}\).*/\1/"`
CPASS=`perl -e "print crypt('${FLAGS_password}', '$SALT');"`
${ADDUSER_BIN} -c "${FLAGS_user}" -m -s /bin/false -p ${CPASS} ${FLAGS_user}
if [ "$?" != "0" ]; then
    echoerr "L'utilisateur \"${FLAGS_user}\" n'a pas ete cree !"
    exit 7
fi

#
# Affectation des quotas
#
if [ "${FLAGS_quota}" != "0" ]; then
    let "quotas=${FLAGS_quota}*1000"
    ${SETQUOTA_BIN} -u ${FLAGS_user} 0 ${quotas} 0 0 /
    if [ "$?" != "0" ]; then
        echoerr "L'affectation des quotas a echoue !"
        exit 8
    fi
fi

#
# Génération du template apache2
#
cat ${APACHE_WWW_TPL} | sed "s/%%domain%%/${FLAGS_website}/g" | sed "s/%%user%%/${FLAGS_user}/g" > /etc/apache2/sites-available/0_${FLAGS_website}
cat ${AWSTATS_TPL} | sed "s/%%domain%%/${FLAGS_website}/g" | sed "s/%%user%%/${FLAGS_user}/g" > /etc/awstats/awstats.${FLAGS_website}.conf

#
# Génération du fichier .htpasswd
#
echo "${FLAGS_user}:${CPASS}" > /home/${FLAGS_user}/.htpasswd

#
# Affectation des droits
#
mkdir /home/${FLAGS_user}/www
chown -R ${FLAGS_user}:${FLAGS_user} /home/${FLAGS_user}
chmod 755 -R /home/${FLAGS_user}
chmod 751 /home/${FLAGS_user}

#
# Ajout de la base MySQL
#
if [ ${FLAGS_mysql} -eq ${FLAGS_TRUE} ]; then
    # Création de l'utilisateur MySQL
    ${MYSQL_BIN} -u root -p${MYSQL_PASS} -e "CREATE USER '${FLAGS_user}'@'localhost' IDENTIFIED BY '${FLAGS_password}';"
    if [ "$?" != "0" ]; then
        echoerr "Creation de l'utilisateur MySQL '${FLAGS_user}' echouee  !"
        exit 9
    fi
  
    # Mise en place des droits utilisateurs
    ${MYSQL_BIN} -u root -p${MYSQL_PASS} -e "GRANT USAGE ON * . * TO '${FLAGS_user}'@'localhost' IDENTIFIED BY '${FLAGS_password}' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0 ;"
    if [ "$?" != "0" ]; then
        echoerr "Affectation des droits utilisateur MySQL echouee !"
        exit 10
    fi
  
    # Création de la base de donnees
    ${MYSQL_BIN} -u root -p${MYSQL_PASS} -e "CREATE DATABASE IF NOT EXISTS ${FLAGS_user};"
    if [ "$?" != "0" ]; then
        echoerr "Creation de la base de donnees echouee !"
        exit 11
    fi
  
    # Affection des droits utilisateur sur la base de donnees
    ${MYSQL_BIN} -u root -p${MYSQL_PASS} -e "GRANT ALL PRIVILEGES ON ${FLAGS_user} . * TO '${FLAGS_user}'@'localhost';"
    if [ "$?" != "0" ]; then
        echoerr "Affection des droits utilisateur sur la base de donnees echouee !"
        exit 12
    fi
fi

#
# Activation des sites
#
a2ensite 0_${FLAGS_website}

#
# Mise en place des statistiques
#
mkdir -p /var/www/cgi-bin/${FLAGS_user} && chown root:root /var/www/cgi-bin && chmod 701 /var/www/cgi-bin && chown ${FLAGS_user}:${FLAGS_user}  /var/www/cgi-bin/${FLAGS_user} && chmod 701 /var/www/cgi-bin/${FLAGS_user} && ln -s /var/www/cgi-bin/${FLAGS_user} /home/${FLAGS_user}/cgi-bin && chmod 755 /usr/share/awstats/
if [ -f /usr/lib/cgi-bin/awstats.pl ]; then
    cp /usr/lib/cgi-bin/awstats.pl /var/www/cgi-bin/${FLAGS_user}/awstats.pl && chown ${FLAGS_user}:${FLAGS_user} /var/www/cgi-bin/${FLAGS_user}/awstats.pl && chmod 755 /var/www/cgi-bin/${FLAGS_user}/awstats.pl
fi



echo "############################################"
echo "# "
echo "# Le domaine ${FLAGS_website} a ete cree :"
echo "# "
echo "# - repertoire : /home/${FLAGS_user}"
if [ "${FLAGS_quota}" != "0" ]; then
    echo "# - quota : ${FLAGS_quota} Mo"
else
    echo "# - quota : aucun"
fi
echo "# - login FTP : ${FLAGS_user}"
echo "# - pass FTP : ${FLAGS_password}"
echo "# - repertoire : /home/${FLAGS_user}"
if [ ${FLAGS_mysql} -eq ${FLAGS_TRUE} ]; then
    echo "# - base de donnees : ${FLAGS_user}"
    echo "# - login mysql : ${FLAGS_user}"
    echo "# - pass mysql : ${FLAGS_password}"
else
    echo "# - aucune base de donnees"
fi
echo "# "
echo "# PENSEZ A REDEMARRER APACHE !!!"
echo "# "
echo "############################################"

exit 0
