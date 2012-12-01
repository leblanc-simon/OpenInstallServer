#!/bin/bash

#
# ./add_ftp.sh --user "mon_user" --password "mon mot de passe" [--quota 500] [--help]
#
# Sortie possible :
# - 0  : OK
# - 1  : Binaire manquant
# - 2  : Mauvaises options
# - 3  : Mauvais formatage du nom d'utilisateur (vide)
# - 4  : Mauvais formatage du nom d'utilisateur (caractères incorrects)
# - 5  : Mauvais formatage du mot de passe (vide)
# - 6  : Nom d'utilisateur déjà existant
# - 7  : Erreur lors de la création de l'utilisateur
# - 8  : Erreur lors de l'affectation des quotas


SCRIPT_DIRECTORY=`( cd -P $(dirname $0); pwd)`

ADDUSER_BIN=`which useradd`
SETQUOTA_BIN=`which setquota`

#
# Ecrit une chaine sur la sortie d'erreur
#
function echoerr()
{
    echo "$@" 1>&2
}


# Vérification des binaires
if [ "${ADDUSER_BIN}" = "" ] || [ "${SETQUOTA_BIN}" = "" ] ]; then
    echoerr "adduser ou setquota non trouve !"
    exit 1
fi

# On inclut le super script shflags :-)
. ${SCRIPT_DIRECTORY}/shflags

# Définition des options
DEFINE_string "user" "" "Le nom d'utilisateur a utiliser" "u"
DEFINE_string "password" "" "Le mot de passe du compte" "p"
DEFINE_integer "quota" 500 "Le quota affecte au compte en Mo (0 pour aucun quota)" "q"

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

# - le mot de passe ne peut pas etre null
if [ "${FLAGS_password}" = "" ]; then
    echo "Le mot de passe ne peut pas etre vide"
    exit 5
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
echo "# "
echo "############################################"

exit 0
