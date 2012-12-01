#!/bin/bash

# Erreurs de sortie :
# 1 : Nombre d'argument insuffisant
# 2 : Argument de script inconnu
# 3 : Le script a executer n'existe pas
# 4 : Nombre d'argument incorrect

# Paramètres
SCRIPT_DIRECTORY=`( cd -P $(dirname $0); pwd)`
TODAY=`date +"%Y%m%d"`
SCRIPTS_DIR="${SCRIPT_DIRECTORY}/scripts/"
LOG_FILENAME="${SCRIPT_DIRECTORY}/logs/qlossh_${TODAY}.log"

##############################################################################
#
# Fonctions
#

log(){
  actual_time=`date +"%Y-%m-%d:%T"`
  echo "${actual_time} $1" >> "${LOG_FILENAME}"
  if [ $# -eq 2 ]; then
    echo "$1"
  fi
}

include_script(){
  script_name="${SCRIPTS_DIR}${1}"

  if [ ! -f "${script_name}" ]; then
    log "Le script ${script_name} n'existe pas !" 1
    exit 3
  fi

  log "On lance ${script_name}"
  source "${script_name}"
}

check_nb_args(){
  # 1 : nombre d'arguments attendus
  # 2 : nombre d'arguments reçus
  args_expect=$1
  args_get=$2

  if [ ${args_expect} -ne ${args_get} ]; then
    log "Nombre d'argument incorrect" 1
    exit 4
  fi
}

##############################################################################
#
# Programme principal
#

NB_ARGS=$#

log "Lancement de $0 avec les arguments : $*"

# On vérifie le nombre d'argument
if [ ${NB_ARGS} -lt 1 ]; then
  log "Nombre d'argument insuffisant !" 1
  exit 1
fi

# En fonction du premier argument, on execute le bon script
case $1 in
  # Ajout d'un site web
  add_site )
    log "Cas : add_site"
    # On vérifie le nombre d'arguments (6 : [add_site], [website], [password], [user], [quota] et [mysql])
    check_nb_args 6 ${NB_ARGS}
    
    # On prépare les variables
    website="${2}"
    password="${3}"
    user="${4}"
    quota="${5}"
    mysql="${6}"

    # On execute le script
    include_script "add_site.sh"
    ;;
    
  # Suppression d'un site web
  remove_site )
    log "Cas : remove_site"
    # On vérifie le nombre d'arguments (2 : [remove_site] et [website])
    check_nb_args 2 ${NB_ARGS}
    
    # On prépare les variables
    website="${2}"

    # On execute le script
    include_script "remove_site.sh"
    ;;

  # Ajoute d'un sous-domaine
  add_sd )
    log "Cas : add_sd"

    # On verifie le nombre d'arguments (3 : [add_sd], [website] et [mysql])
    check_nb_args 3 ${NB_ARGS}

    # On prepare les variables
    website="${2}"
    mysql="${3}"

    # On execute le script
    include_script "add_sd.sh"
    ;;

  # Ajoute d'un sous-domaine
  remove_sd )
    log "Cas : remove_sd"

    # On verifie le nombre d'arguments (2 : [remove_sd] et [website])
    check_nb_args 2 ${NB_ARGS}

    # On prepare les variables
    website="${2}"

    # On execute le script
    include_script "remove_sd.sh"
    ;;
    
  # Redemarrage d'un service
  restart )
    log "Cas : restart"

    # On verifie le nombre d'arguments (2 : [restart] et [nom du service])
    check_nb_args 2 ${NB_ARGS}

    # On prepare la variable
    service=${2}

    # On execute le script
    include_script "restart.sh"
    ;;

  # Fixation d'un quota
  fix_quota )
    log "Cas : fix_quota"

    # On verifie le nombre d'arguments (3 : [fix_quota], [user] et [quota])
    check_nb_args 3 ${NB_ARGS}

    # On prepare les variables
    user="${2}"
    quota="${3}"
    
    # On execute le script
    include_script "fix_quota.sh"
    ;;
    
  # Tous les autres cas
  * )
    echo "Aucun script a executer !"
    exit 2
    ;;
esac

echo "On sort"
exit 0
