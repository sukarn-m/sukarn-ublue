#!/usr/bin/env bash
set -euo pipefail

nas_mount=/var/mnt/nas

user_string=$(grep 1000:1000 /etc/passwd) #Look for user with UID and GID of 1000
if [[ -z "$user_string" ]]; then
  echo "ERROR: No user with UID:GID 1000:1000 found in /etc/passwd"
  exit 1
fi
IFS=':' read -r -a user_array <<< "$user_string" #Split by :
USERNAME=${user_array[0]} #Set username
HOMEDIR=${user_array[5]} #Set home directory

EXPIRY_DATE=$(/usr/bin/ssh-keygen -Lf "$HOMEDIR/.ssh/id_ed25519-cert.pub" | /usr/bin/grep Valid | /usr/bin/sed -e 's/T[0-9\:]\+//g' -e 's/^\ \+Valid\:\ from\ [0-9]\+\-[0-9]\+\-[0-9]\+\ to\ //')
DAYS_UNTIL_EXPIRY=$(( ($(date --date="$EXPIRY_DATE" +%s) - $(date +%s))/(60*60*24) ))
DAYS_UNTIL_RENEWAL=$(( DAYS_UNTIL_EXPIRY - 365 ))

echo "$DAYS_UNTIL_RENEWAL days left until certificate renewal."

if [ "$DAYS_UNTIL_RENEWAL" -lt "0" ]
then
	echo "Trying to renew the certificate."
	HOSTNAME=$(/usr/bin/hostnamectl hostname)
	/usr/bin/mkdir -p "$nas_mount/$HOSTNAME/ssh"
	/usr/bin/cp "$HOMEDIR/.ssh/id_ed25519.pub" "$nas_mount/$HOSTNAME/ssh/$HOSTNAME.pub"
	echo "Files are in place. Let the waiting games begin."
	MAX_WAIT=60
	WAIT_COUNT=0
	while [ ! -f "$nas_mount/$HOSTNAME/ssh/${HOSTNAME}-cert.pub" ]
	do
	    WAIT_COUNT=$((WAIT_COUNT + 1))
	    if [ "$WAIT_COUNT" -ge "$MAX_WAIT" ]; then
	        echo "ERROR: Timed out waiting for certificate after $((MAX_WAIT * 60)) seconds."
	        exit 1
	    fi
	    /usr/bin/echo "File not found. Waiting... ($WAIT_COUNT/$MAX_WAIT)"
	    /usr/bin/sleep 60
	done
	/usr/bin/echo "Found the file! Waiting another 5 seconds for good luck..."
	/usr/bin/sleep 5
	/usr/bin/cp "$nas_mount/$HOSTNAME/ssh/${HOSTNAME}-cert.pub" "$HOMEDIR/.ssh/id_ed25519-cert.pub"
	/usr/bin/rm -r "$nas_mount/$HOSTNAME/ssh"
	/usr/bin/chcon -t ssh_home_t "$HOMEDIR/.ssh/id_ed25519-cert.pub"
	/usr/bin/chown "$USERNAME:$USERNAME" "$HOMEDIR/.ssh/id_ed25519-cert.pub"
	EXPIRY_DATE=$(/usr/bin/ssh-keygen -Lf "$HOMEDIR/.ssh/id_ed25519-cert.pub" | /usr/bin/grep Valid | /usr/bin/sed -e 's/T[0-9\:]\+//g' -e 's/^\ \+Valid\:\ from\ [0-9]\+\-[0-9]\+\-[0-9]\+\ to\ //')
	DAYS_UNTIL_EXPIRY=$(( ($(date --date="$EXPIRY_DATE" +%s) - $(date +%s))/(60*60*24) ))
	echo "New certificate is valid until $EXPIRY_DATE"
else
	echo "Current certificate is valid until $EXPIRY_DATE"
fi
