#!/bin/bash

CONFIG_DIR=~/.config/openvpn-applet
export CONFIG_DIR
CONFIG_FILE_PATH=$CONFIG_DIR/config
export CONFIG_FILE_PATH
sleepTime=10

################################################################################
# Functions                                                                    #
################################################################################
function display_help() {
	# Display Help
	echo "Helper to display openvpn3 connection state."
	echo
	echo "Syntax: ./openvpn3applet.sh [-h|-s n]"
	echo "options:"
	echo "-s [seconds]     Time between state refresh in seconds, default: 10"
	echo "-h     Print this Help."
	echo
}

function set_sleep_time() {
	if ! [[ $1 =~ $re ]]; then
		echo $(date) " | " "Invalid number for sleepTime, using default (10s)"
	else
		sleepTime=$1
	fi
}

function select_and_save_configfile() {
	configfile=$(yad --width="500" --center --title="Select config file" --text="\nPlease select your openvpn3 config file:\n" --button="OK" --file --file-filter="*.ovpn")
	# create directory in case it does not exist
	mkdir -p $CONFIG_DIR
	echo "OPENVPN_CONFIG_PATH="$configfile >$CONFIG_FILE_PATH
	OPENVPN_CONFIG_PATH=$configfile
	echo $(date) " | " "Selected configfile: " $OPENVPN_CONFIG_PATH
}
export -f select_and_save_configfile

# add handler to manage process shutdown
function on_exit() {
	exec 3<>$PIPE
	echo $(date) " | " "Quitting.."
	echo "quit" >&3
	rm -f $PIPE
}
export -f on_exit

# add handler for tray icon left click
function on_click() {
	update_state
}
export -f on_click

function disconnect() {
	echo $(date) " | " "Disconnecting.."
	exec 3<>$PIPE
	echo "icon:$RUNNING_DIR/icons/icon-blue.svg" >&3
	sessionPath=$(openvpn3 sessions-list | grep Path | awk ' { print $2 } ')
	openvpn3 session-manage --disconnect --session-path $sessionPath
	update_state
	echo $(date) " | " "Disconnected."
}
export -f disconnect

function connect() {
	echo $(date) " | " "Connecting..."
	exec 3<>$PIPE
	echo "icon:$RUNNING_DIR/icons/icon-blue.svg" >&3
	openvpn3 session-start --config $OPENVPN_CONFIG_PATH
	update_state
}
export -f connect

function update_state() {
	exec 3<>$PIPE
	defaultMenuEntries="|Select config!bash -c 'select_and_save_configfile'|Exit!bash -c 'on_exit'"
	statEntry="|Stats!bash -c 'display_session_stats'"

	detectedState=false
	output=$(openvpn3 sessions-list)
	while IFS= read -r line; do
		if [[ $line = "No sessions available" || $line = *"Client authentication failed: Authentication failed" ]]; then
			echo $(date) " | " "Not connected"
			echo "icon:$RUNNING_DIR/icons/icon-red.svg" >&3
			echo "menu:Connect!bash -c 'connect'" $defaultMenuEntries >&3
			echo "tooltip:Not connected" >&3
			detectedState=true
		elif [[ $line = *"Client connected" ]]; then
			echo $(date) " | " "Session found!"
			echo "icon:$RUNNING_DIR/icons/icon-green.svg" >&3
			echo "menu:Disconnect!bash -c 'disconnect'" $statEntry $defaultMenuEntries >&3
			echo "tooltip:Connected to VPN" >&3
			detectedState=true
		elif [[ $line = *"Web authentication required to connect" ]]; then
			echo $(date) " | " "Waiting for web authentication"
			echo "icon:$RUNNING_DIR/icons/icon-blue.svg" >&3
			echo "menu:Disconnect!bash -c 'disconnect'" $statEntry $defaultMenuEntries >&3
			echo "tooltip:Waiting for Web authentiction (check webbrowser)" >&3
			detectedState=true
		fi
	done <<<"$output"

	# failsafe for unknown states
	if [[ $detectedState = false ]]; then
		echo $(date) " | " "Unknown state"
		echo "icon:$RUNNING_DIR/icons/icon-red.svg" >&3
		echo "menu:Connect!bash -c 'connect'" $defaultMenuEntries >&3
		echo "tooltip:Not connected" >&3
	fi

}
export -f update_state

function display_session_stats() {
	sessionPath=$(openvpn3 sessions-list | grep Path | awk ' { print $2 } ')
	output=$(openvpn3 session-stats -o $sessionPath)
	yad --width=500 --title="session-stats" --text="$output" --center --button="Close"
}
export -f display_session_stats

################################################################################
# End of functions (make sure to export them)                                  #
################################################################################

################################################################################
# Start of script                                                              #
################################################################################
while getopts s:h flag; do
	case "${flag}" in
	s)
		echo "mklsdljf" ${OPTARG}
		if ! [[ ${OPTARG} =~ ^[0-9]+$ ]]; then
			echo $(date) " | " "Invalid number for sleepTime, using default ("$sleepTime"s)"
		else
			sleepTime=${OPTARG}
			echo $(date) " | " "Using sleepTime:" $sleepTime
		fi
		;;
	h)
		display_help
		exit
		;;
	esac
done

# check if there is a saved vpn config file, if not, ask for one and save it
if [ -f "$CONFIG_FILE_PATH" ]; then
	source $CONFIG_FILE_PATH
fi

if [[ -z $OPENVPN_CONFIG_PATH || $OPENVPN_CONFIG_PATH = "" ]]; then
	select_and_save_configfile
fi
export OPENVPN_CONFIG_PATH

# create a FIFO file, used to manage the I/O redirection from shell
PIPE=$(mktemp -u --tmpdir ${0##*/}.XXXXXXXX)
export PIPE
mkfifo $PIPE

# attach a file descriptor to the file
exec 3<>$PIPE

trap on_exit EXIT

RUNNING_DIR=${BASH_SOURCE%/*}
export RUNNING_DIR

# create the notification icon
yad --notification \
	--listen \
	--image="$RUNNING_DIR/icons/icon-red.svg" \
	--text="openvpn3-applet" \
	--command="bash -c 'on_click'" <&3 &
notifpid=$!

while true; do
	if ! ps -p $notifpid >/dev/null; then
		# exit if yad process has been terminated
		exit
	fi
	update_state
	sleep $sleepTime
done
