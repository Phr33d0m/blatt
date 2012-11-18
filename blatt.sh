#!/usr/bin/env bash
# blatt - (Gentoo) build log arch testing tool
# by Denis M. (Phr33d0m)

ARGCOUNT=1
E_WRONGARGS=33
if [[ $# -lt $ARGCOUNT ]]; then
	echo "Simple tool to find build system issues."
	echo "Usage: blatt.sh [package log file]"
	exit $E_WRONGARGS
fi

CMD_GREP=$(command -v egrep)
CMD_GREP_ARGS="-i --color=always"

CMDS=""
ISSUES=""
DOSTUFF="all"


### COLOURS

NORM=$(tput sgr0) #NORMal
RED=$(tput setaf 1)	
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BOLD=$(tput bold)

#LIME_YELLOW=$(tput setaf 190)
#POWDER_BLUE=$(tput setaf 153)
#BLUE=$(tput setaf 4)
#MAGENTA=$(tput setaf 5)
#CYAN=$(tput setaf 6)
#WHITE=$(tput setaf 7)
#BRIGHT=$(tput bold)
#BLINK=$(tput blink)
#REVERSE=$(tput smso)
#UNDERLINE=$(tput smul)

#Takes: Filename / Sets: bare PN
function getpn(){
	PN=$(basename $1 | sed 's%\(.*\):\(.*\)-[0-9]\..*%\1/\2%')
}

### HARDCODED CALLS
# Set up our grep command
for i in $(ls --color=never /usr/bin/x86_64-pc-linux-gnu-* | sed 's:/usr/bin/x86_64-pc-linux-gnu-::g'); do
	CMDS+="^"$i" |";
done
CMDS=${CMDS%?} #Slice off last character

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
fi
