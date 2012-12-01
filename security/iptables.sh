#!/bin/bash
#
# This file is part of the OpenIptables.
# (c) 2012  Simon Leblanc <contact@leblanc-simon.eu>
#
# For the full copyright and license information, please view the LICENSE
# file that was distributed with this source code.
#
# License BSD <http://www.opensource.org/licenses/bsd-license.php>
#

################################################################################
#
# Variables
#
################################################################################
PROG_VERSION="0.0.1"
PROG_NAME="OpenIptables"
SCRIPT_NAME=`basename $0`
SCRIPT_DIRECTORY=`( cd -P $(dirname $0); pwd)`
CONFIG_DIRECTORY="${SCRIPT_DIRECTORY}/config"
IPTABLES_BIN=""

OPT_VERBOSE=false
OPT_FLUSH=false


################################################################################
#
# Functions
#
################################################################################

#
# Write a string in the stderr
#
function echoerr()
{
    echo "$@" 1>&2
}


#
# Check if the user is root
#
function is_root()
{
    if [ "${UID}" -ne "0" ]; then
        echoerr "You must be root. No root has small dick :-)"
        exit 1
    fi
    
    return 0
}


#
# Show the version of the program
#
function version()
{
    echo "Version ${PROG_NAME} ${PROG_VERSION}"
    
    return 0
}


#
# Show the help of the program
#
function usage()
{
    echo "${SCRIPT_NAME} [-f] [-h] [-v] [-V]"
    echo ""
    echo "Options :"
    echo "  -f : clean only this script rules"
    echo "  -h : print this help"
    echo "  -v : set verbose mode"
    echo "  -V : print version"
    echo ""
    echo "Distribued under BSD License : Simon Leblanc <contact@leblanc-simon.eu>"
    version
    
    return 0
}


#
# Get the iptables binary
#
function init_iptables_bin()
{
    iptables_binary=`which iptables`
    if [ "$?" != "0" ]; then
        echoerr "No iptables binary found!"
        return 1
    fi
    
    IPTABLES_BIN="${iptables_binary}"
    return 0
}


#
# Execute an iptables command
# @param    string  iptables_cmd    the options to append in the iptables command
#
function execute_iptables_cmd()
{
    iptables_cmd="$@"
    
    if [ ${OPT_VERBOSE} == true ]; then
        echo "Add rule : ${iptables_cmd}"
    fi
    
    `${IPTABLES_BIN} ${iptables_cmd}`
    #echo "${IPTABLES_BIN} ${iptables_cmd}"
    
    if [ "$?" != "0" ]; then
        echoerr "Fail to add rule : ${iptables_cmd}"
        return 1
    else
        if [ ${OPT_VERBOSE} == true ]; then
            echo "The rule : ${iptables_cmd} is added"
        fi
    fi
    
    return 0
}


#
# Add a rule in the iptables
# @param    string  chain       the chain where add the rule
# @param    int     port        the port affected by the rule
# @param    string  ip          the ip affected by the rule (default: '')
# @param    string  rule        the rule (default: ACCEPT)
# @param    string  protocol    the protocol affected by the rule (default: tcp)
#
function add_ip()
{
    if [ $# -eq 2 ]; then
        chain="$1"
        port="$2"
        ip=""
        rule="ACCEPT"
        protocol="tcp"
    elif [ $# -eq 3 ]; then
        chain="$1"
        port="$2"
        ip="$3"
        rule="ACCEPT"
        protocol="tcp"
    elif [ $# -eq 4 ]; then
        chain="$1"
        port="$2"
        ip="$3"
        rule="$4"
        protocol="tcp"
    elif [ $# -eq 5 ]; then
        chain="$1"
        port="$2"
        ip="$3"
        rule="$4"
        protocol="$5"
    else
        echoerr "Bad number of args for add_ip : get $#, expected 2, 3, 4 or 5"
        return 1
    fi
    
    command_iptables="-A ${chain} -p ${protocol} --dport ${port}"
    
    if [ "${ip}" != "" ]; then
        command_iptables="${command_iptables} -s ${ip}"
    fi
    
    command_iptables="${command_iptables} -j ${rule}"
    
    execute_iptables_cmd "${command_iptables}"
    
    return 0
}


#
# Remove a rule in the iptables
# @param    string  chain       the chain where add the rule
# @param    int     port        the port affected by the rule
# @param    string  ip          the ip affected by the rule (default: '')
# @param    string  rule        the rule (default: ACCEPT)
# @param    string  protocol    the protocol affected by the rule (default: tcp)
#
function remove_ip()
{
    if [ $# -eq 2 ]; then
        chain="$1"
        port="$2"
        ip=""
        rule="ACCEPT"
        protocol="tcp"
    elif [ $# -eq 3 ]; then
        chain="$1"
        port="$2"
        ip="$3"
        rule="ACCEPT"
        protocol="tcp"
    elif [ $# -eq 4 ]; then
        chain="$1"
        port="$2"
        ip="$3"
        rule="$4"
        protocol="tcp"
    elif [ $# -eq 5 ]; then
        chain="$1"
        port="$2"
        ip="$3"
        rule="$4"
        protocol="$5"
    else
        echoerr "Bad number of args for add_ip : get $#, expected 2, 3, 4 or 5"
        return 1
    fi
    
    command_iptables="-D ${chain} -p ${protocol} --dport ${port}"
    
    if [ "${ip}" != "" ]; then
        command_iptables="${command_iptables} -s ${ip}"
    fi
    
    command_iptables="${command_iptables} -j ${rule}"
    
    execute_iptables_cmd "${command_iptables}"
    return 0
}


#
# Add the rules counter scan
#
function counter_scan_begin()
{
    if [ ${OPT_FLUSH} == false ]; then
        action="A"
        action_chain="N"
    else
        action="D"
        action_chain="X"
    fi
    
    execute_iptables_cmd "-${action} INPUT -p tcp -m recent --name w00tlist --update --seconds 21600 -j DROP"

    if [ ${OPT_FLUSH} == false ]; then
        execute_iptables_cmd "-${action_chain} w00tchain"
    fi
    
    execute_iptables_cmd "-${action} w00tchain -m recent --set --name w00tlist -p tcp -j REJECT --reject-with tcp-reset"

    if [ ${OPT_FLUSH} == false ]; then
        execute_iptables_cmd "-${action_chain} w00t"
    fi
    
    execute_iptables_cmd "-${action} INPUT -p tcp -j w00t"

}


#
# Add the rules counter scan
#
function counter_scan_end()
{
    if [ ${OPT_FLUSH} == false ]; then
        action="A"
    else
        action="D"
    fi
    
    execute_iptables_cmd "-${action} w00t -m recent -p tcp --syn --dport 80 --set"
    execute_iptables_cmd "-${action} w00t -m recent -p tcp --tcp-flags PSH,SYN,ACK SYN,ACK --sport 80 --update"
    execute_iptables_cmd "-${action} w00t -m recent -p tcp --tcp-flags PSH,SYN,ACK ACK --dport 80 --update"
    execute_iptables_cmd "-${action} w00t -m recent -p tcp --tcp-flags PSH,ACK PSH,ACK --dport 80 --remove -m string --to 80 --algo bm --hex-string '|485454502f312e310d0a0d0a|' -j w00tchain"
    
    if [ ${OPT_FLUSH} == true ]; then
        execute_iptables_cmd "-X w00t"
        execute_iptables_cmd "-X w00tchain"
    fi
}


#
# Add the ban's rules
#
function add_ban_rules()
{
    for ip in "${ban_ips[@]}"; do
        if [ ${OPT_FLUSH} == false ]; then
            execute_iptables_cmd "-A INPUT -s ${ip} -j DROP"
        else
            execute_iptables_cmd "-D INPUT -s ${ip} -j DROP"
        fi
    done
}


#
# Add the local's rules
#
function add_local_rules()
{
    if [ ${OPT_FLUSH} == false ]; then
        action="A"
    else
        action="D"
    fi
    
    # exist connection
    execute_iptables_cmd "-${action} INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT"
    
    # loopback
    execute_iptables_cmd "-${action} INPUT -i lo -j ACCEPT"
    execute_iptables_cmd "-${action} OUTPUT -o lo -j ACCEPT"
    
    # icmp
    execute_iptables_cmd "-${action} INPUT -p icmp -j ACCEPT"
    execute_iptables_cmd "-${action} OUTPUT -p icmp -j ACCEPT"
    
    # local connection
    execute_iptables_cmd "-${action} INPUT -p tcp --source 192.168.0.0/16 -j ACCEPT"
    execute_iptables_cmd "-${action} INPUT -p udp --source 192.168.0.0/16 -j ACCEPT"
}


#
# Add the services' rules
#
function add_services_rules()
{
    for service in ${services[@]}; do
        allow_service="allow_${service}"
        if [ ${!allow_service} == true ]; then
            if [ ${OPT_VERBOSE} == true ]; then
                echo "Service ${service} is allow"
            fi
            
            service_ports="${service}_ports[@]"
            service_protocols="${service}_protocols[@]"
            service_ips="${service}_ips[@]"
            nb_ips="${service}_ips[*]"; nb_ips=${!nb_ips};
            
            for port in ${!service_ports}; do
                for protocol in ${!service_protocols}; do
                    if [ "${nb_ips}" == "" ]; then
                        if [ ${OPT_FLUSH} == false ]; then
                            add_ip "INPUT" "${port}" "" "ACCEPT" "${protocol}"
                        else
                            remove_ip "INPUT" "${port}" "" "ACCEPT" "${protocol}"
                        fi
                    else
                        for ip in ${!service_ips}; do
                            if [ ${OPT_FLUSH} == false ]; then
                                add_ip "INPUT" "${port}" "${ip}" "ACCEPT" "${protocol}"
                            else
                                remove_ip "INPUT" "${port}" "${ip}" "ACCEPT" "${protocol}"
                            fi
                        done
                    fi
                done
            done
        else
            if [ ${OPT_VERBOSE} == true ]; then
                echo "Service ${service} is not allow"
            fi
        fi
    done
}


#
# Add the final rule : DROP ALL
#
function drop_all()
{
    if [ ${OPT_FLUSH} == false ]; then
        execute_iptables_cmd "-A INPUT -j DROP"
    else
        execute_iptables_cmd "-D INPUT -j DROP"
    fi
}


#
# Get options and parse it
# @param    string  getopts     the command line args
#
function get_options()
{
    while getopts ":fvVh" opt; do
        case ${opt} in
            h)
                usage
                exit 0
            ;;
            
            v)
                OPT_VERBOSE=true
            ;;
            
            V)
                version
                exit 0
            ;;
            
            f)
                OPT_FLUSH=true
            ;;

            \?)
                echoerr "Invalid option: -$OPTARG"
                echo ""
                usage
                exit 1
            ;;
        esac
    done
}


################################################################################
#
# Program
#
################################################################################

# Get options
get_options "$@"

# Check if you are root
is_root

# get iptables binary
init_iptables_bin
if [ $? -ne 0 ]; then
    exit 2
fi

# get default configuration
if [ ! -f "${CONFIG_DIRECTORY}/default.sh" ]; then
    echoerr "No default config file!"
    exit 3
fi
. "${CONFIG_DIRECTORY}/default.sh"

# get special configuration
if [ -f "${CONFIG_DIRECTORY}/$(hostname).sh" ]; then
    . "${CONFIG_DIRECTORY}/$(hostname).sh"
else
    # No fatal error!
    echoerr "No hostname config file!"
fi

# Add anti-scan rules
counter_scan_begin

# Add ban rules
add_ban_rules

# Add local rules
add_local_rules

# Add services rules
add_services_rules

# Add anti-scan rules
counter_scan_end

# Add DROP all
drop_all

exit 0

