#!/bin/bash


#
# Ecrit une chaine sur la sortie d'erreur
#
function echoerr()
{
    echo "$@" 1>&2
}

#
# This function with all alphabetic characters converted to uppercase.
# @param    string      $1|STDIN string
# @return   string
# @see      http://codebase.tuxnet24.de/index.php?ref=snippet&space=1&container=21&snippets=138
#
function strtoupper() 
{
    if [ -n "$1" ]; then
        echo $1 | tr '[:lower:]' '[:upper:]'
    else
        cat - | tr '[:lower:]' '[:upper:]'
    fi
}


#
# Retourne la date actuelle
# @return   string      la date actuelle
#
function get_date()
{
    local str_date=`date "+%Y-%m-%d:%H:%M:%S"`
    echo "${str_date}"
}


#
# Crée le répertoire des logs
#
function create_log_dir()
{
    if [ -d "${LOG_DIRECTORY}" ]; then
        return 0
    fi
    
    mkdir -p "${LOG_DIRECTORY}"
    
    if [ "$?" -ne "0" ]; then
        echoerr "Impossible de creer le repertoire de log : ${LOG_DIRECTORY}"
        exit 1
    fi
    
    return 0
}


#
# Ajoute un contenu dans un fichier
# @param    string      Le nom du fichier
# @param    string      Le contenu à ajouter
#
function write_file()
{
    local filename=${1}
    local content=${2}
    
    create_log_dir
    
    if [ ! -f "${filename}" ]; then
        touch "${filename}"
    fi
    
    echo "${content}" >> "${filename}" && return 0
    
    return 1
}


#
# Log un événement
# @param    string      niveau de log (fatal | error | info)
# @param    string      contenu à logger
# @param    int         affiche le contenu du log à l'écran
#
function logger()
{
    local level=${1}
    local content=${2}
    local screen=${3}
    
    log_content="$(strtoupper ${level})	$(get_date)	${content}"
    write_file "${LOG_FILENAME}" "$log_content"
    
    if [ "${screen}" -eq "1" ]; then
        if [ "${level}" != "info" ]; then
            echoerr "$log_content"
        else
            echo "$log_content"
        fi
    fi
    
    return 0
}


#
# Log un événement de type erreur fatal
# @param    string      contenu à logger
#
function logFatal()
{
    local content=${1}
    logger "fatal" "${content}" 1 
    
    exit 1
}


#
# Log un événement de type erreur
# @param    string      contenu à logger
#
function logError()
{
    local content=${1}
    logger "error" "${content}" 1
    
    return 0
}


#
# Log un événement de type info
# @param    string      contenu à logger
#
function logInfo()
{
    local content=${1}
    logger "info" "${content}" 0
    
    return 0
}


#
# Vérifie que l'utilisateur a bien les droits root
# Si l'utilisateur n'a pas les droits root, on quitte le script
#
function is_root()
{
    if [ "${UID}" -ne "0" ]; then
        logFatal "You must be root. No root has small dick :-)"
    fi
    
    return 0
}


#
# Vérifie si le serveur est un serveur Web
# A utiliser comme cela : isNotWeb && exit
# @return   int     1 si c'est un serveur web, 0 sinon
#
function isNotWeb()
{
    if [ ! -d /etc/apache2 ]; then
        return 0
    fi
    
    return 1
}


#
# Vérifie si le serveur est un serveur OpenERP
# A utiliser comme cela : isNotOpenerp && exit
# @return   int     1 si c'est un serveur OpenERP, 0 sinon
#
function isNotOpenerp()
{
    if [ ! -d /home/openerp ]; then
        return 0
    fi
    
    return 1
}