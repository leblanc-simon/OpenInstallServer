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


# define owner ips
owner_ips=('127.0.0.1')

# Define ban ips
ban_ips=()

# Define allow ips
ssh_ips=("${owner_ips[*]}")
ftp_ips=("${owner_ips[*]}")
mysql_ips=("${owner_ips[*]}")
postgres_ips=("${owner_ips[*]}")
openerp_ips=()
apache_ips=()
webmin_ips=("${owner_ips[*]}")
mail_ips=()
telnet_ips=("${owner_ips[*]}")
dns_ips=()
rsync_ips=("${owner_ips[*]}")
oco_ips=()
snmp_ips=("${owner_ips[*]}")

# Define port services
ssh_ports=(22)
ftp_ports=(21)
mysql_ports=(3306)
postgres_ports=(5432)
openerp_ports=(8069 8070)
apache_ports=(80 443)
webmin_ports=(10000)
mail_ports=(110 143 465 587 993 995)
telnet_ports=(23)
dns_ports=(53)
rsync_ports=(873)
oco_ports=(79)
snmp_ports=(161)

# Define protcol services
ssh_protocols=('tcp')
ftp_protocols=('tcp')
mysql_protocols=('tcp')
postgres_protocols=('tcp')
openerp_protocols=('tcp')
apache_protocols=('tcp')
webmin_protocols=('tcp')
mail_protocols=('tcp')
telnet_protocols=('tcp')
dns_protocols=('tcp' 'udp')
rsync_protocols=('tcp')
oco_protocols=('tcp')
snmp_protocols=('udp')

# Allow services
allow_ssh=true
allow_ftp=false
allow_mysql=false
allow_postgres=false
allow_openerp=false
allow_apache=false
allow_webmin=false
allow_mail=false
allow_telnet=false
allow_dns=false
allow_rsync=false
allow_oco=false
allow_snmp=true

# Define services
services=('ssh' 'ftp' 'mysql' 'postgres' 'openerp' 'apache' 'webmin' 'mail' 'telnet' 'dns' 'rsync' 'oco' 'snmp')
