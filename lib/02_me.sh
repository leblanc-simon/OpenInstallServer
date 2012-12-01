#!/bin/bash


#
# Met à jour les données à partir du gestionnaire de version
#
function update_me()
{
    if [ -d "${SCRIPT_DIRECTORY}/.svn" ]; then
        updateMeBySvn
        if [ $? -ne 0 ]; then
            return 1
        fi
    elif [ -d "${SCRIPT_DIRECTORY}/.git" ]; then
        updateMeByGit
        if [ $? -ne 0 ]; then
            return 1
        fi
    else
        logError "Impossible de determine le gestionnaire de version"
        return 1
    fi
    
    return 0
}


#
# Met à jour les données à partir du SVN
#
function updateMeBySvn()
{
    which svn > /dev/null || apt-get -y -q install subversion
    if [ "$?" != "0" ]; then
        logError "Impossible d'installer subversion"
        return 1
    fi
    
    cd "${SCRIPT_DIRECTORY}"
    svn update
    if [ "$?" != "0" ]; then
        logError "Erreur lors de la mise a jour du depot"
        return 1
    fi
    
    return 0
}


#
# Met à jour les données à partir du Git
#
function updateMeByGit()
{
    which git > /dev/null || apt-get -y -q install git-core
    if [ "$?" != "0" ]; then
        logError "Impossible d'installer git"
        return 1
    fi
    
    cd "${SCRIPT_DIRECTORY}"
    git pull
    if [ "$?" != "0" ]; then
        logError "Erreur lors de la mise a jour du depot"
        return 1
    fi
    
    return 0
}