#!/bin/sh
### Makes a full backup, mysqldump, and copies to a remote server
### also deletes the old incremental backups
# created by: Luong, Monica 
# date: 11/2020

HOME="<HOME_DIR>"
DATE=$(date +\%F)
BACKUPDIR="$HOME/mysqldumps"
REMOTE="<REMOTE>"
REMOTEDIR="<REMOTE_DIR>"
LOGDIR="/var/lib/mysql"
BINLOG=$(/usr/bin/sudo find $LOGDIR -name "binlog.0*" -mtime 0)

# create the mysqldump/full backup
/usr/bin/mysqldump --defaults-extra-file=$HOME/.mylogin.cnf -u root --single-transaction \
	--quick --lock-tables=false --routines \
	--all-databases > $BACKUPDIR/full-backup-$DATE.sql

if [ $? -eq 0 ] ; then
	echo "copied dump to $BACKUPDIR" | /usr/bin/logger
else
	echo "couldn't copy dump to $BACKUPDIR" | /usr/bin/logger
	exit 1
fi

# delete backups & bin logs in the local backup dir that are older than 2wks
/usr/bin/sudo find $BACKUPDIR -maxdepth 1 -type f -mtime +14 -delete

# rsync to keep local backup directory in sync with remote backup directory
/usr/bin/rsync -aqz -e "ssh -i $HOME/.ssh/id_rsa" $BACKUPDIR/ \
	        $REMOTE:$REMOTEDIR/ 2>&1 | /usr/bin/logger

# delete the old incremental backups, from last week
# these are located in the log directory
/usr/bin/mysql --defaults-extra-file=$HOME/.mylogin.cnf -u root \
	-e "PURGE BINARY LOGS TO '$BINLOG';" 2>&1 | /usr/bin/logger 
