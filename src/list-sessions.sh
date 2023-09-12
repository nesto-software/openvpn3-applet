#! /bin/bash

YAD_OPTIONS="--window-icon='dialog-information' --name=IxSysinfo"

KEY=$RANDOM

# main dialog
TXT="<b>Current sessions:</b>\\n\\n"
TXT+="$(openvpn3 sessions-list)\\n"

openvpn3 sessions-list | grep -v "\-\-\-" | grep -v "Session name" | sed -r "s/^[^:]*:\s//" | sed -r "s/\s\s.*//" |
	yad --notebook --width=1000 --height=450 --title="System info" --text="$TXT" --button=Close \
		--key=$KEY --list --column="Path" --column="Created" --column="Owner" --column="Config name" --column="Status"
