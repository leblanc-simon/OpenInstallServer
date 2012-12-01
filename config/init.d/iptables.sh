#! /bin/sh
### BEGIN INIT INFO
# Provides:          firewall (OpenIptables)
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Lancement des regles de bases du firewall
# Description:       Lancement des regles de bases du firewall
#
### END INIT INFO

# Author: Simon Leblanc <contact@leblanc-simon.eu>
#

# Do NOT "set -e"

# PATH should only include /usr/* if it runs after the mountnfs.sh script
PATH=/sbin:/usr/sbin:/bin:/usr/bin:/root/travaux/security
DESC="Definition des regles de bases du firewall"
NAME=iptables.sh
DAEMON=/root/travaux/security/iptables.sh
DAEMON_ARGS=""
PIDFILE=/var/run/$NAME.pid
SCRIPTNAME=/etc/init.d/$NAME

# Exit if the package is not installed
[ -x "$DAEMON" ] || exit 0

# Read configuration variable file if it is present
[ -r /etc/default/$NAME ] && . /etc/default/$NAME

# Load the VERBOSE setting and other rcS variables
. /lib/init/vars.sh

# Define LSB log_* functions.
# Depend on lsb-base (>= 3.0-6) to ensure that this file is present.
. /lib/lsb/init-functions

VERBOSE="yes"

#
# Function that starts the daemon/service
#
do_start()
{
	if [ -f "${PIDFILE}" ]; then
		return 1
	fi

	${DAEMON}

	if [ "$?" != "0" ]; then
		return 2
	fi

	touch $PIDFILE

	return 0
}

#
# Function that stops the daemon/service
#
do_stop()
{
	if [ ! -f "${PIDFILE}" ]; then
		return 0
	fi
	
	${DAEMON} -f

	if [ "$?" != "0" ]; then
                return 2
        fi
	
	rm -f $PIDFILE

        return 0
}
case "$1" in
  start)
	[ "$VERBOSE" != no ] && log_daemon_msg "Starting $DESC" "$NAME"
	do_start
	case "$?" in
		0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
		2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
	esac
	;;
  stop)
	[ "$VERBOSE" != no ] && log_daemon_msg "Stopping $DESC" "$NAME"
	do_stop
	case "$?" in
		0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
		2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
	esac
	;;
  restart|force-reload)
	#
	# If the "reload" option is implemented then remove the
	# 'force-reload' alias
	#
	log_daemon_msg "Restarting $DESC" "$NAME"
	do_stop
	case "$?" in
	  0|1)
		do_start
		case "$?" in
			0) log_end_msg 0 ;;
			1) log_end_msg 1 ;; # Old process is still running
			*) log_end_msg 1 ;; # Failed to start
		esac
		;;
	  *)
	  	# Failed to stop
		log_end_msg 1
		;;
	esac
	;;
  *)
	echo "Usage: $SCRIPTNAME {start|stop|restart|force-reload}" >&2
	exit 3
	;;
esac
