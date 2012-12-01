#!/bin/bash


#
# Vérifie que l'utilisateur a bien les droits root
# Si l'utilisateur n'a pas les droits root, on quitte le script
#
function is_root()
{
    if [ "${UID}" -ne "0" ]; then
        echo "You must be root. No root has small dick :-)"
        exit 1
    fi
}


#
# Ajoute une ligne au message qui sera afficher en fin d'installation
# @param    string      La ligne à ajouter
#
function addInEndMessage()
{
    end_message="${end_message}\n# - ${1}"
}


#
# Affiche le message de fin et quitte le script
#
function printEndMessage()
{
    addInEndMessage "PENSEZ A EXECUTER LE SCRIPT deploy.sh"
    
    echo "#######################################################"
    echo "# "
    echo "# L'installation s'est bien deroulee"
    echo "# "
    echo "# Recapitulatif :"
    echo -e "# ${end_message}"
    echo "# "
    echo "#######################################################"
    exit 0
}


#
# Demande le hostname
#
function getHostname()
{
    while [ -z "${hostname_change}" ]; do
        echo -e "Souhaitez-vous changer le hostname [y/N] : \c"
        read hostname_change
        
        if [ "${hostname_change}" == "" ]; then
            hostname_change="n"
        elif [ "${hostname_change}" != "y" ] && [ "${hostname_change}" != "Y" ] && [ "${hostname_change}" != "n" ] && [ "${hostname_change}" != "N" ]; then
            hostname_change=""
        elif [ "${hostname_change}" == "Y" ]; then
            hostname_change="y"
        fi
    done
    
    if [ "${hostname_change}" == "y" ]; then
        while [ -z "${new_hostname}" ]; do
            echo -e "Veuillez indiquer le hostname : \c"
            read new_hostname
        done
    fi
}


#
# Demande l'adresse mail de communication par défaut
#
function getMailAddress()
{
    cat ${SCRIPT_DIRECTORY}/../config/dotfiles/common/.techmail | grep '@' > /dev/null
    if [ $? -eq 0 ]; then
        return 0
    fi
    
    while [ -z "${email_address}" ]; do
        echo -e "Adresse e-mail a utiliser : \c"
        read email_address
    done
    
    echo "${email_address}" > ${SCRIPT_DIRECTORY}/../config/dotfiles/common/.techmail
    sed -i "s/MailTo =/MailTo = ${email_address}/" ${SCRIPT_DIRECTORY}/../config/logwatch/common/conf/logwatch.conf
    sed -i "s/destemail =/destemail = ${email_address}/" ${SCRIPT_DIRECTORY}/../config/fail2ban/common/jail.conf
    
    addInEndMessage "L'adresse email utilisee est : ${email_address}"
}


#
# Demande des adresse IP par défaut
#
function getIpAddress()
{
    cat ${SCRIPT_DIRECTORY}/../security/config/default.sh | grep "owner_ips=('127.0.0.1')" > /dev/null
    if [ $? -ne 0 ]; then
        return 0
    fi
    
    while [ -z "${ip_address}" ]; do
        echo -e "Adresses IP a utiliser (separer par des espaces) : \c"
        read ip_address
    done
    
    ip_php="'127.0.0.1', "
    ip_security="'127.0.0.1' "
    ip_conf="127.0.0.1\/8 "
    for ip in ${ip_address}; do
        ip_php="${ip_php}'${ip}', "
        ip_security="${ip_security}'${ip}' "
        ip_conf="${ip_conf}${ip} "
    done
    
    sed -i "s/allow from 127.0.0.1/allow from ${ip_conf}/" ${SCRIPT_DIRECTORY}/../config/phpmyadmin/common/apache.conf
    sed -i "s/array('127.0.0.1')/array(${ip_php})/" ${SCRIPT_DIRECTORY}/../config/phpmyadmin/common/config.inc.php
    sed -i "s/ignoreip = 127.0.0.1\/8/ignoreip = ${ip_conf}/" ${SCRIPT_DIRECTORY}/../config/fail2ban/common/jail.conf
    sed -i "s/owner_ips=('127.0.0.1')/owner_ips=(${ip_security})/" ${SCRIPT_DIRECTORY}/../security/config/default.sh
    
    addInEndMessage "Les adresses IP autorisees sont : ${ip_address}"
}


#
# Demande de le mot de passe root pour MySQL
#
function getMySQLPasswd()
{
    while [ -z "${mysql_password}" ]; do
        echo -e "Mot de passe root pour MySQL : \c"
        read mysql_password
    done
    
    echo "${mysql_password}" > /root/.pdb && chmod 400 /root/.pdb
}


#
# Demande les données pour PostgreSQL
#
function getDatasPostgres()
{
    while [ -z "${postgres_hostname}" ]; do
        echo -e "Hote pour PostgreSQL : \c"
        read postgres_hostname
    done
    
    while [ -z "${postgres_username}" ]; do
        echo -e "Utilisateur pour PostgreSQL : \c"
        read postgres_username
    done
    
    while [ -z "${postgres_password}" ]; do
        echo -e "Mot de passe pour PostgreSQL : \c"
        read postgres_password
    done
    
    echo "${postgres_hostname}" > /root/.pg_host && chmod 400 /root/.pg_host
    echo "${postgres_username}" > /root/.pg_user && chmod 400 /root/.pg_user
    echo "${postgres_password}" > /root/.pg_pass && chmod 400 /root/.pg_pass
}


#
# Update du hostname
#
function updateHostname()
{
    if [ "${hostname_change}" == "y" ]; then
        hostname "${new_hostname}"
        if [ $? -ne 0 ]; then
            echo "Echec de la modification du hostname" 1>&2
            exit 2
        fi
        
        echo "${new_hostname}" > /etc/hostname
        if [ $? -ne 0 ]; then
            echo "Echec de la modification du fichier /etc/hostname" 1>&2
            exit 3
        fi
        
        addInEndMessage "Le hostname a ete modifie en : ${new_hostname}"
    fi
}


#
# Mise à jour du système
#
function updateSystem()
{
    apt-get -y update
    if [ $? -ne 0 ]; then
        echo "Echec lors de la mise a jour des depots" 1>&2
        exit 4
    fi
    
    apt-get -y -o Dpkg::Options::=--force-confold upgrade
    if [ $? -ne 0 ]; then
        echo "Echec de la mise a jour du systeme" 1>&2
        exit 5
    fi
}


#
# Paramétrage des outils de base
#
function parameterBase()
{
    debconf-set-selections <<< "postfix postfix/main_mailer_type select Internet Site"
    debconf-set-selections <<< "postfix postfix/mailname string $(hostname)"
    
    debconf-set-selections <<< "proftpd-basic shared/proftpd/inetd_or_standalone select	standalone"
}


#
# Installation des outils de base
#
function installBase()
{
    apt-get -y install bzr git-core subversion python-subversion lftp at ntp zip htp rsync iptables curl mailutils imagemagick ffmpeg snmpd
    if [ $? -ne 0 ]; then
        echo "Echec de l'installation de base du systeme" 1>&2
        exit 6
    fi
    
    addInEndMessage "installation des outils de base [OK]"
}


#
# Installation de fail2ban
#
function installFail2ban()
{
    apt-get -y install fail2ban
    if [ $? -ne 0 ]; then
        echo "Echec de l'installation de fail2ban" 1>&2
        exit 7
    fi
    
    addInEndMessage "installation de fail2ban [OK]"
}


#
# Installation de munin
#
function installMunin()
{
    apt-get -y install munin munin-plugins-extra
    if [ $? -ne 0 ]; then
        echo "Echec de l'installation de munin" 1>&2
        exit 8
    fi
    
    addInEndMessage "installation de munin [OK]"
}


#
# Installation de postfix
#
function installPostfix()
{
    apt-get -y install postfix
    if [ $? -ne 0 ]; then
        echo "Echec de l'installation de postfix" 1>&2
        exit 9
    fi
    
    addInEndMessage "installation de postfix [OK]"
}


#
# Installation de logwatch
#
function installLogwatch()
{
    apt-get -y install logwatch
    if [ $? -ne 0 ]; then
        echo "Echec de l'installation de logwatch" 1>&2
        exit 10
    fi
    
    addInEndMessage "installation de logwatch [OK]"
}


#
# Installation de proftpd
#
function installProftpd()
{
    apt-get -y install proftpd-basic
    if [ $? -ne 0 ]; then
        echo "Echec de l'installation de proftpd" 1>&2
        exit 11
    fi
    
    addInEndMessage "installation de proftpd [OK]"
}


#
# Installation des outils de gestion de quotas
#
function installQuotas()
{
    apt-get -y install quota quotatool
    if [ $? -ne 0 ]; then
        echo "Echec de l'installation des outils de gestion de quotas" 1>&2
        exit 12
    fi
    
    local message="installation des outils de quotas [OK]\n# \n"
    message="${message}# PENSEZ A AJOUTER \"usrquota,grpquota\" DANS LA\n"
    message="${message}# PARTITION AU NIVEAU DE /etc/fstab\n"
    message="${message}# PUIS : mount -o remount /home\n"
    message="${message}# ET ENFIN : quotacheck -vagum && quotaon -avug\n# "
    
    addInEndMessage "${message}"
}


#
# Installation des outils pour LAMP
#
function installLamp()
{
    debconf-set-selections <<< "mysql-server-5.5 mysql-server/root_password password ${mysql_password}"
    debconf-set-selections <<< "mysql-server-5.5 mysql-server/root_password_again password ${mysql_password}"
    
    apt-get -y install php5 php5-cgi php5-cli php5-curl php5-ffmpeg php5-gd php5-imagick php5-imap php5-intl \
                        php5-mcrypt php5-mysql php5-sqlite php5-suhosin php5-xmlrpc php5-xsl php-apc php-pear \
                        mysql-server-5.5 mysql-client \
                        apache2 apache2-suexec-custom apache2-utils libapache2-mod-evasive libapache2-mod-php5 libapache2-modsecurity libapache2-mod-suphp
    if [ $? -ne 0 ]; then
        echo "Echec de l'installation de LAMP" 1>&2
        exit 13
    fi
    
    # fix d'un bug de mod-security
    if [ ! -f /usr/lib/libxml2.so.2 ]; then
        ln -s /usr/lib/x86_64-linux-gnu/libxml2.so.2 /usr/lib/libxml2.so.2
    fi
    
    # Activation des modules de base
    a2enmod suexec
    a2enmod rewrite
    a2enmod expires
    a2enmod vhost_alias
    a2enmod headers
    
    addInEndMessage "installation de LAMP [OK]"
}


#
# Installation de PhpMyAdmin
#
function installPhpMyAdmin()
{
    debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password"
    debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
    debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password ${mysql_password}"
    debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password"
    debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2"
    
    apt-get -y install phpmyadmin
    if [ $? -ne 0 ]; then
        echo "Echec de l'installation de PhpMyAdmin" 1>&2
        exit 14
    fi
    
    addInEndMessage "installation de PhpMyAdmin [OK]"
}


#
# Installation de awstats
#
function installAwstats()
{
    apt-get -y install awstats
    if [ $? -ne 0 ]; then
        echo "Echec de l'installation de awstats" 1>&2
        exit 15
    fi
    
    addInEndMessage "installation de awstats [OK]"
}


#
# Déplace les fichiers de log
#
function moveLog()
{
    if [ -L /var/log ]; then
        return 0
    fi
    
    service rsyslog stop && mv /var/log /home/ && ln -s /home/log /var/log && service rsyslog start
    if [ $? -ne 0 ]; then
        echo "Echec du deplacement des fichiers de logs" 1>&2
        exit 16
    fi
    
    addInEndMessage "deplacement des fichiers de log [OK]"
}


#
# Déplace les fichiers de MySQL
#
function moveMySQLData()
{
    if [ -L /var/lib/mysql ]; then
        return 0
    fi
    
    service mysql stop && mv /var/lib/mysql /home/ && ln -s /home/mysql /var/lib/mysql
    if [ $? -ne 0 ]; then
        echo "Echec du deplacement des fichiers de MySQL" 1>&2
        exit 17
    fi
    
    # Modification de AppArmor
    perl -pi -e "s/\/var\/lib\/mysql\/\*\* rwk,/\/var\/lib\/mysql\/\*\* rwk,\n  \/home\/mysql\/ r,\n  \/home\/mysql\/\*\* rwk,\n  \/home\/log\/mysql\/ r,\n  \/home\/log\/mysql\/\* rw,/" /etc/apparmor.d/usr.sbin.mysqld
    if [ $? -ne 0 ]; then
        echo "Echec de la modification d'AppArmor pour MySQL" 1>&2
        exit 18
    fi
    
    service mysql start
    
    addInEndMessage "deplacement des fichiers de MySQL [OK]"
}


#
# Construit le fichier de backup
#
function buildBackupFile()
{
    local backup_file="${SCRIPT_DIRECTORY}/../utils/backup/$(hostname).pl"
    
    echo "$1" | grep "web" > /dev/null
    local mysql=$?
    
    echo "$1" | grep "openerp" > /dev/null
    local postgres=$?
    
    # On vide le fichier
    echo "" > "${backup_file}"
    
    if [ ${mysql} -eq 0 ] && [ ${postgres} -eq 0 ]; then
        echo "\$Conf{DumpPreUserCmd} = '\$sshPath -q -x -l root \$host /root/travaux/utils/backup/backup.sh -m -p';" >> "${backup_file}"
    elif [ ${mysql} -eq 0 ]; then
        echo "\$Conf{DumpPreUserCmd} = '\$sshPath -q -x -l root \$host /root/travaux/utils/backup/backup.sh -m';" >> "${backup_file}"
    elif [ ${postgres} -eq 0 ]; then
        echo "\$Conf{DumpPreUserCmd} = '\$sshPath -q -x -l root \$host /root/travaux/utils/backup/backup.sh -p';" >> "${backup_file}"
    fi
    
    echo -e "\$Conf{BackupFilesExclude} = {\n  '/home' => [\n    '/enova',\n    '/log',\n    '/mysql',\n    '/lost+found'\n  ]\n};" >> "${backup_file}"
    echo -e "\$Conf{RsyncShareName} = [\n  '/home',\n  '/etc',\n  '/root'\n];" >> "${backup_file}"

    addInEndMessage "creation du fichier template de backup dans ${backup_file} [OK]"
    addInEndMessage "PENSEZ A EXECUTER (sur le serveur BackupPC) : /root/travaux/utils/add_backuppc_host.sh $(hostname)"
}


#
# Crée un utilisateur avec un mot de passe aléatoire
#
# @param    string      user    Le nom d'utilisateur à créer
#
function createUser()
{
    local user="$1"
    
    # Création du mot de passe
    local salt=`head -c 10 /dev/urandom | perl -e 'use MIME::Base64 qw(encode_base64);print encode_base64(<>);' | sed "s/\(.\{2\}\).*/\1/"`
    local password=`head -c 10 /dev/urandom | perl -e 'use MIME::Base64 qw(encode_base64);print encode_base64(<>);' | sed "s/\(.\{8\}\).*/\1/"`
    local crypt_pass=`perl -e "print crypt('${password}', '${salt}');"`
    
    # Vérification de la non-existance de l'utilisateur
    cat /etc/shadow | grep "${user}:" > /dev/null
    if [ $? -eq 0 ]; then
        echo "Le nom d'utilisateur \"${user}\" existe deja" 1>&2
        exit 19
    fi
    
    # Ajout de l'utilisateur
    useradd -c "${user}" -m -s /bin/bash -p ${crypt_pass} ${user}
    if [ $? -ne 0 ]; then
        echo "L'utilisateur \"${user}\" n'a pas ete cree !" 1>&2
        exit 20
    fi
    
    addInEndMessage "Utilisateur ${user} cree avec le mot de passe \"${password}\" [OK]"
}
