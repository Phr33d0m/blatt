#!/usr/bin/env bash
# blatt - (Gentoo) build log arch testing tool
# by Denis M. (Phr33d0m)

ARGCOUNT=1
E_WRONGARGS=33
if [[ $# -lt $ARGCOUNT ]]; then
	echo "Simple tool to find build system issues."
	echo "Usage: $(basename $0) /path/to/logs-dir/<cat>:<pkg>-<ver>-....log"
	exit $E_WRONGARGS
fi

CMD_GREP=$(command -v egrep)
CMD_GREP_ARGS="--color=always"

CMDS=""
CMDS_ALT=""
ISSUES=""
DOSTUFF="all"
PKG_NAME=""

### COLOURS
NORM=$(tput sgr0) #NORMal
RED=$(tput setaf 1)	
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BOLD=$(tput bold)

#Takes: Filename / Sets: bare PN
function getpn(){
	PN=$(basename $1 | sed 's%\(.*\):\(.*\)-[0-9]\..*%\1/\2%')
}

### HARDCODED CALLS
# Set up our grep command
for i in $(ls --color=never /usr/bin/x86_64-pc-linux-gnu-* | sed 's:/usr/bin/x86_64-pc-linux-gnu-::g'); do
	CMDS+="^"$i" |";
	CMDS_ALT+="libtool.* "$i"|";
done
CMDS=${CMDS%?} #Slice off last character
CMDS_ALT=${CMDS_ALT%?} #Slice off last character

CMDS=$(echo $CMDS | sed 's:\+:\\+:g;s:\-:\\-:g')
CMDS_ALT=$(echo $CMDS_ALT | sed 's:\+:\\+:g;s:\-:\\-:g')
#    if [ -f $1 ]; then
#	PKG_NAME=`echo $1 | xargs -n 1 basename | sed 's/:/\//;s/:.*//;s/\(.*\)-[0-9]\..*/\1/'`
#    else
#	echo "ERROR: File does not exist."
#	exit 1
#   fi

HARDCALLS=0 #Boolean
function hardcalls(){ # 1: filename 2: PN
	TREACLE=$($CMD_GREP $CMD_GREP_ARGS "$CMDS" $1)
	if [[ $TREACLE ]]; then
		I_HARDCALLPN=("${I_HARDCALLPN[@]}" "$2")
		I_HARDCALL_LINES=("${I_HARDCALL_LINES[@]}" "$TREACLE")
		let HARDCALLS++
	else
		echo -e $GREEN$2" is clean"$NORM
	fi
}



### MAIN STORY
### Call requested tests on each desired file
for I in $*; do
	getpn $I
	case $DOSTUFF in
		'hardcalls'|'all')
			hardcalls $I $PN
	esac
done

ISSUES=$HARDCALLS # Can just keep attaching things as tests get added. Any non-negative value makes the if true.

if [[ $ISSUES ]]; then
	echo -e $RED">>> ISSUES FOUND!"
	if [[ $HARDCALLS ]]; then
		echo -e $BOLD$YELLOW"> Hardcoded calls:"$NORM
		for ((I=0; I<=$HARDCALLS; I++ )); do
			echo $BOLD$YELLOW"${I_HARDCALLPN[$I]}"$NORM
			echo "${I_HARDCALL_LINES[$I]}"
		done
	fi
else
	echo -e "$BOLD$GREEN>>> NO ISSUES FOUND"$NORM
#
#
#if [[ `$CMD_GREP $CMD_GREP_ARGS "'$CMDS'" $1 | wc -l` -gt 0 ]]; then
#    ISSUES="${ISSUES} hardcalls-issue"
#fi
#
#if [[ `$CMD_GREP $CMD_GREP_ARGS "'$CMDS_ALT'" $1 | wc -l` -gt 0 ]]; then
#    ISSUES="${ISSUES} hardcalls-issue"
#fi
#
#
#### MAIN STORY
##
#if [[ `echo $ISSUES | grep -c 'issue'` -gt 0 ]]; then
#    echo -e $BLDRED">>> ISSUES FOUND!"
#    if echo $ISSUES | grep -q 'hardcalls-issue'; then
#	echo -e $BLDYLW"> Hardcoded calls:"
#	$CMD_GREP $CMD_GREP_ARGS "'$CMDS'" $1
#	$CMD_GREP $CMD_GREP_ARGS "'$CMDS_ALT'" $1
#    fi
#else
#    echo -e $BLDGRN">>> NO ISSUES FOUND"
fi
