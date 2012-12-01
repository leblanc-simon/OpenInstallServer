#!/bin/bash

# question sur les différents mots de passe
echo "Mot de passe pour MySQL : "
read mysql_password
if [[ "${mysql_password}" == "" ]]; then
    echo "Un mot de passe pour MySQL est obligatoire !"
    echo "Arret de l'installation."
    exit 1
fi

# sauvegarde du mot de passe mysql dans /root/.pdb
echo "${mysql_password}" > /root/.pdb && chmod 400 /root/.pdb

# Mise à jour des paquets
apt-get -y update
apt-get -y -o Dpkg::Options::=--force-confold upgrade

# Initilisation des variables de apt-get
debconf-set-selections <<< "proftpd-basic shared/proftpd/inetd_or_standalone select	standalone"
debconf-set-selections <<< "mysql-server-5.5 mysql-server/root_password password ${mysql_password}"
debconf-set-selections <<< "mysql-server-5.5 mysql-server/root_password_again password ${mysql_password}"
debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password"
debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password ${mysql_password}"
debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password"
debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2"
debconf-set-selections <<< "postfix postfix/main_mailer_type select Internet Site"
debconf-set-selections <<< "postfix postfix/mailname string $(hostname)"

# installation de base du serveur
apt-get -y install bzr git-core subversion python-subversion lftp at ntp zip htp rsync iptables curl mailutils

# installation de lamp
apt-get -y install php5 php5-cgi php5-cli php5-curl php5-ffmpeg php5-gd php5-imagick php5-imap php5-intl php5-mcrypt php5-mysql php5-sqlite php5-suhosin php5-xmlrpc php5-xsl php-apc php-pear \
                   mysql-server-5.5 mysql-client \
                   apache2 apache2-suexec-custom apache2-utils libapache2-mod-evasive libapache2-mod-php5 libapache2-modsecurity libapache2-mod-suphp \
                   imagemagick ffmpeg
                   
# fix d'un bug de mod-security
if [ ! -f /usr/lib/libxml2.so.2 ]; then
    ln -s /usr/lib/x86_64-linux-gnu/libxml2.so.2 /usr/lib/libxml2.so.2
fi

# installation de fail2ban
apt-get -y install fail2ban

# installation de phpmyadmin
apt-get -y install phpmyadmin

# installation de munin
apt-get -y install munin munin-plugins-extra

# installation de postfix
apt-get -y install postfix postfix-mysql 

# installation de logwatch
apt-get -y install logwatch

# installation de proftpd
apt-get -y install proftpd-basic

# installation de awstats
apt-get -y install awstats

# installation des éléments pour les quotas
apt-get -y install quota quotatool

# (des)activation de module apache
a2enmod suexec
a2enmod rewrite
a2enmod expires
a2enmod vhost_alias
a2enmod headers

# Parce que c'est toujours utile, on fait un updatedb
updatedb

# application des différents fichiers de configuration
echo "#######################################################"
echo "#"
echo "# PENSEZ A AJOUTER \"usrquota,grpquota\" DANS LA "
echo "# PARTITION AU NIVEAU DE /etc/fstab"
echo "# PUIS : mount -o remount /home"
echo "# ET ENFIN : quotacheck -vagum && quotaon -avug"
echo "#"
echo "#######################################################"

exit 0
