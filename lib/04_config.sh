#!/bin/bash

#
# Mise à jour du fichier de configuration d'iptables
#
function update_iptables()
{
    config_iptables="${SCRIPT_DIRECTORY}/security/config/`hostname`.sh"
    sample_iptables="${SCRIPT_DIRECTORY}/security/config/sample.sh"
    
    if [ ! -f ${config_iptables} ]; then
        cp -p ${sample_iptables} ${config_iptables}
        if [ $? -ne 0 ]; then
            logError "echec de la copie de la configuration par defaut de iptables"
            return 1
        fi
    fi
    
    return 0
}


#
# Mise à jour des fichiers de configuration init.d en fonction d'un répertoire donné
# @param    string  basedir     Le répertoire où sont situés les fichiers de configuration
#
function update_initd_for()
{
    local basedir="$1"
    local initfiles=`find ${basedir} -maxdepth 1 -type f`
    for initfile in ${initfiles}; do
        if [ ! -f "${initfile}" ]; then
            cp -pf "${initfile}" /etc/init.d/
            if [ $? -ne 0 ]; then
                logError "echec de la copie de ${initfile} dans init.d"
                return 1
            fi
            
            chmod 755 "${initfile}"
            
            update-rc.d $(basename "${initfile}") defaults
            if [ $? -ne 0 ]; then
                logError "echec de la mise en place $(basename ${initfile}) dans rc.d"
                return 2
            fi
        else
            cp -pf "${initfile}" /etc/init.d/
            if [ $? -ne 0 ]; then
                logError "echec de la copie de ${initfile} dans init.d"
                return 3
            fi
        fi
    done
    
    return 0
}


#
# Mise à jour des fichiers de configuration init.d
#
function update_initd()
{
    # Les fichiers init.d commun à tous les serveurs
    update_initd_for "${CONFIG_DIRECTORY}/init.d"
    if [ $? -ne 0 ]; then
        logError "echec de la mise à jour des fichier init.d commun"
        return 1
    fi
    
    # Les fichiers init.d pour les serveur web
    isNotWeb
    if [ $? -ne 0 ]; then
        update_initd_for "${CONFIG_DIRECTORY}/init.d/web"
        if [ $? -ne 0 ]; then
            logError "echec de la mise à jour des fichier init.d web"
            return 2
        fi
    fi
    
    # Les fichiers init.d pour les serveur openerp
    isNotOpenerp
    if [ $? -ne 0 ]; then
        update_initd_for "${CONFIG_DIRECTORY}/init.d/openerp"
        if [ $? -ne 0 ]; then
            logError "echec de la mise à jour des fichier init.d openerp"
            return 3
        fi
    fi
    
    # Les fichiers init.d pour un serveur spécifique
    if [ -d "${CONFIG_DIRECTORY}/init.d/$(hostname)" ]; then
        update_initd_for "${CONFIG_DIRECTORY}/init.d/$(hostname)"
        if [ $? -ne 0 ]; then
            logError "echec de la mise à jour des fichier init.d specifique"
            return 4
        fi
    fi
    
    return 0
}


#
# Mise à jour des fichiers de configuration apache
#
function update_apache()
{
    isNotWeb && return 0
    
    # Copie des fichiers communs de configuration
    cp -fr ${CONFIG_DIRECTORY}/apache/common/* /etc/apache2/
    if [ $? -ne 0 ]; then
        logError "echec de la copie du dossier ${CONFIG_DIRECTORY}/apache/common"
        return 1
    fi
    
    # Copie des fichiers spécifique de configuration
    if [ -d "${CONFIG_DIRECTORY}/apache/$(hostname)" ]; then
        cp -fr ${CONFIG_DIRECTORY}/apache/$(hostname)/* /etc/apache2/
        if [ $? -ne 0 ]; then
            logError "echec de la copie du dossier ${CONFIG_DIRECTORY}/apache/$(hostname)"
            return 1
        fi
    fi
    
    return 0
}


#
# Met à jour les fichiers de configuration utilisateur
#
function update_dotfiles()
{
    # Copie des fichiers communs de configuration
    dotfiles=`ls -a "${CONFIG_DIRECTORY}/dotfiles/common/" | grep -v -E -e "^(\.|\.\.|\.svn)$"`
    
    for dotfile in ${dotfiles}; do
        cp "${CONFIG_DIRECTORY}/dotfiles/common/${dotfile}" /root/
        if [ $? -ne 0 ]; then
            logError "echec de la copie de ${CONFIG_DIRECTORY}/dotfiles/common/${dotfile}"
            return 1
        fi
    done
    
    # Copie des fichiers spécifique de configuration
    if [ -d "${CONFIG_DIRECTORY}/dotfiles/$(hostname)" ]; then
        dotfiles=`ls -a "${CONFIG_DIRECTORY}/dotfiles/$(hostname)/" | grep -v -E -e "^(\.|\.\.|\.svn)$"`
    
        for dotfile in ${dotfiles}; do
            cp "${CONFIG_DIRECTORY}/dotfiles/$(hostname)/${dotfile}" /root/
            if [ $? -ne 0 ]; then
                logError "echec de la copie de ${CONFIG_DIRECTORY}/dotfiles/$(hostname)/${dotfile}"
                return 1
            fi
        done
    fi
    
    return 0
}


#
# Mise à jour des fichiers de configuration fail2ban
#
function update_fail2ban()
{
    # Copie des fichiers communs de configuration
    cp -fr ${CONFIG_DIRECTORY}/fail2ban/common/* /etc/fail2ban/
    if [ $? -ne 0 ]; then
        logError "echec de la copie du dossier ${CONFIG_DIRECTORY}/fail2ban/common"
        return 1
    fi
    
    # Copie des fichiers spécifique de configuration
    if [ -d "${CONFIG_DIRECTORY}/fail2ban/$(hostname)" ]; then
        cp -fr ${CONFIG_DIRECTORY}/fail2ban/$(hostname)/* /etc/fail2ban/
        if [ $? -ne 0 ]; then
            logError "echec de la copie du dossier ${CONFIG_DIRECTORY}/fail2ban/$(hostname)"
            return 1
        fi
    fi
    
    return 0
}


#
# Mise à jour des fichiers de configuration logwatch
#
function update_logwatch()
{
    # Copie des fichiers communs de configuration
    cp -fr ${CONFIG_DIRECTORY}/logwatch/common/* /etc/logwatch/ && mkdir -p /var/cache/logwatch
    if [ $? -ne 0 ]; then
        logError "echec de la copie du dossier ${CONFIG_DIRECTORY}/logwatch/common"
        return 1
    fi
    
    # Copie des fichiers spécifique de configuration
    if [ -d "${CONFIG_DIRECTORY}/logwatch/$(hostname)" ]; then
        cp -fr ${CONFIG_DIRECTORY}/logwatch/$(hostname)/* /etc/logwatch/
        if [ $? -ne 0 ]; then
            logError "echec de la copie du dossier ${CONFIG_DIRECTORY}/logwatch/$(hostname)"
            return 1
        fi
    fi
    
    return 0
}


#
# Mise à jour des fichiers de configuration fail2ban
#
function update_php()
{
    isNotWeb && return 0
    
    # Copie des fichiers communs de configuration
    cp -f ${CONFIG_DIRECTORY}/php/common/php.ini /etc/php5/cgi/php.ini
    if [ $? -ne 0 ]; then
        logError "echec de la copie du fichier ${CONFIG_DIRECTORY}/php/common/php.ini (cgi)"
        return 1
    fi
    
    cp -f ${CONFIG_DIRECTORY}/php/common/php.ini /etc/php5/apache2/php.ini
    if [ $? -ne 0 ]; then
        logError "echec de la copie du fichier ${CONFIG_DIRECTORY}/php/common/php.ini (module)"
        return 1
    fi
    
    # Copie des fichiers spécifique de configuration
    if [ -f "${CONFIG_DIRECTORY}/php/$(hostname)/php.ini" ]; then
        cp -f ${CONFIG_DIRECTORY}/php/$(hostname)/php.ini /etc/php5/cgi/php.ini
        if [ $? -ne 0 ]; then
            logError "echec de la copie du fichier ${CONFIG_DIRECTORY}/php/$(hostname)/php.ini (cgi)"
            return 1
        fi
        
        cp -f ${CONFIG_DIRECTORY}/php/$(hostname)/php.ini /etc/php5/apache2/php.ini
        if [ $? -ne 0 ]; then
            logError "echec de la copie du fichier ${CONFIG_DIRECTORY}/php/$(hostname)/php.ini (module)"
            return 1
        fi
    fi
    
    return 0
}


#
# Mise à jour des fichiers de configuration fail2ban
#
function update_proftpd()
{
    # Copie des fichiers communs de configuration
    cp -fr ${CONFIG_DIRECTORY}/proftpd/common/* /etc/proftpd/
    if [ $? -ne 0 ]; then
        logError "echec de la copie du dossier ${CONFIG_DIRECTORY}/proftpd/common"
        return 1
    fi
    
    # Copie des fichiers spécifique de configuration
    if [ -d "${CONFIG_DIRECTORY}/proftpd/$(hostname)" ]; then
        cp -fr ${CONFIG_DIRECTORY}/proftpd/$(hostname)/* /etc/proftpd/
        if [ $? -ne 0 ]; then
            logError "echec de la copie du dossier ${CONFIG_DIRECTORY}/proftpd/$(hostname)"
            return 1
        fi
    fi
    
    return 0
}


#
# Mise à jour des fichiers de configuration fail2ban
#
function update_phpmyadmin()
{
    isNotWeb && return 0
    
    # Copie des fichiers communs de configuration
    cp -fr ${CONFIG_DIRECTORY}/phpmyadmin/common/* /etc/phpmyadmin/
    if [ $? -ne 0 ]; then
        logError "echec de la copie du dossier ${CONFIG_DIRECTORY}/phpmyadmin/common"
        return 1
    fi
    
    # Copie des fichiers spécifique de configuration
    if [ -d "${CONFIG_DIRECTORY}/phpmyadmin/$(hostname)" ]; then
        cp -fr ${CONFIG_DIRECTORY}/phpmyadmin/$(hostname)/* /etc/phpmyadmin/
        if [ $? -ne 0 ]; then
            logError "echec de la copie du dossier ${CONFIG_DIRECTORY}/phpmyadmin/$(hostname)"
            return 1
        fi
    fi
    
    return 0
}


#
# Mise à jour des fichiers de configuration fail2ban
#
function update_suphp()
{
    isNotWeb && return 0
    
    # Copie des fichiers communs de configuration
    cp -fr ${CONFIG_DIRECTORY}/suphp/common/* /etc/suphp/
    if [ $? -ne 0 ]; then
        logError "echec de la copie du dossier ${CONFIG_DIRECTORY}/suphp/common"
        return 1
    fi
    
    # Copie des fichiers spécifique de configuration
    if [ -d "${CONFIG_DIRECTORY}/suphp/$(hostname)" ]; then
        cp -fr ${CONFIG_DIRECTORY}/suphp/$(hostname)/* /etc/suphp/
        if [ $? -ne 0 ]; then
            logError "echec de la copie du dossier ${CONFIG_DIRECTORY}/suphp/$(hostname)"
            return 1
        fi
    fi
    
    return 0
}


#
# Mise à jour des fichiers de configuration cron en fonction d'un répertoire donné
# @param    string  basedir     Le répertoire où sont situés les fichiers de configuration
#
function update_cron_for()
{
    local basedir="$1"
    cp -fr ${basedir}/* /etc/
    if [ $? -ne 0 ]; then
        logError "echec de la copie du dossier ${basedir}"
        return 1
    fi
}


#
# Mise à jour des fichiers de cron
#
function update_cron()
{
    # Les fichiers cron commun
    update_cron_for "${CONFIG_DIRECTORY}/cron/common"
    if [ $? -ne 0 ]; then
        logError "echec de la mise à jour des fichier cron commun"
        return 1
    fi
    
    # Les fichiers init.d pour les serveur web
    isNotWeb
    if [ $? -ne 0 ]; then
        update_cron_for "${CONFIG_DIRECTORY}/cron/web"
        if [ $? -ne 0 ]; then
            logError "echec de la mise à jour des fichier cron web"
            return 2
        fi
    fi
    
    # Les fichiers init.d pour les serveur openerp
    isNotOpenerp
    if [ $? -ne 0 ]; then
        update_cron_for "${CONFIG_DIRECTORY}/cron/openerp"
        if [ $? -ne 0 ]; then
            logError "echec de la mise à jour des fichier cron openerp"
            return 3
        fi
    fi
    
    # Les fichiers init.d specifique
    if [ -d "${CONFIG_DIRECTORY}/cron/$(hostname)" ]; then
        update_cron_for "${CONFIG_DIRECTORY}/cron/$(hostname)"
        if [ $? -ne 0 ]; then
            logError "echec de la mise à jour des fichier cron $(hostname)"
            return 4
        fi
    fi
    
    # Désactive l'envoi des mail à root
    grep -l -r -E -e "MAILTO=\"?root\"?" /etc/cron* | xargs perl -pi -e 's/MAILTO="?root"?/MAILTO=""/' $1
    
    return 0
}


#
# Mise à jour de SMNP
#
function update_snmp()
{
    # On vérifie que snmpd est installé
    which snmpd > /dev/null || apt-get -q -y install snmpd
    if [ $? -ne 0 ]; then
        logError "echec de la verification et installation de snmpd"
        return 1
    fi
    
    # On met à jour les fichiers de configuration
    cp "${CONFIG_DIRECTORY}/snmp/snmpd.conf" "/etc/snmp/snmpd.conf"
    if [ $? -ne 0 ]; then
        logError "echec de la copie de ${CONFIG_DIRECTORY}/snmp/snmpd.conf"
        return 1
    fi
    
    chmod 600 "/etc/snmp/snmpd.conf"
    if [ $? -ne 0 ]; then
        logError "echec de la modification des droits de /etc/snmp/snmpd.conf"
        return 1
    fi
    
    cp "${CONFIG_DIRECTORY}/snmp/snmpd" "/etc/default/snmpd"
    if [ $? -ne 0 ]; then
        logError "echec de la copie de ${CONFIG_DIRECTORY}/snmp/snmpd"
        return 1
    fi
    
    chmod 644 "/etc/default/snmpd"
    if [ $? -ne 0 ]; then
        logError "echec de la modification des droits de /etc/default/snmpd"
        return 1
    fi
    
    return 0
}
