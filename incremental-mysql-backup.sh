#!/bin/sh
### Makes incremental backups (bin logs) and copies to remote server
# created by: Luong, Monica 
# date: 11/2020

HOME="<HOME_DIR>"
REMOTE="<REMOTE_SERVER>"
REMOTEDIR="$HOME/mysql/dumps"
BACKUPDIR="$HOME/mysqldumps"
LOGDIR="/var/lib/mysql"
BINLOG=$(/usr/bin/sudo find $LOGDIR -name "binlog.0*" -mtime 0) # modified in the last 24hrs

# copy the incremental backup to another directory
cp $BINLOG $BACKUPDIR

if [ $? -eq 0 ] ; then
	echo "copied $BINLOG to $BACKUPDIR" | /usr/bin/logger
elif
	echo "ERROR: couldn't copy $BINLOG to $BACKUPDIR" | /usr/bin/logger
fi

# rsync to keep local backup directory in sync with remote's backup directory
/usr/bin/rsync -aqz -e "ssh -i $HOME/.ssh/id_rsa" $BACKUPDIR/ \
	$REMOTE:$REMOTEDIR/ 2>&1 | /usr/bin/logger

# flush the logs and start a new incremental backup 
/usr/bin/mysql --defaults-extra-file=$HOME/.mylogin.cnf -u root -e "FLUSH LOGS;" \
	2>&1 | /usr/bin/logger
