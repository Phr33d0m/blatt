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


### HARDCODED CALLS

for i in $(ls --color=never /usr/bin/x86_64-pc-linux-gnu-* | sed 's:/usr/bin/x86_64-pc-linux-gnu-::g'); do
	CMDS+="^"$i" |";
done

CMDS=$(sed 's:|$::' <<< $CMDS)

if [[ $($CMD_GREP $CMD_GREP_ARGS "$CMDS" $1) ]]; then
	ISSUES+=" hardcalls"
fi



### MAIN STORY

if [[ $ISSUES ]]; then
	echo -e $RED">>> ISSUES FOUND!"
	if echo $ISSUES | grep -q 'hardcalls'; then
		echo -e $BOLD$YELLOW"> Hardcoded calls:"$NORM
		$CMD_GREP $CMD_GREP_ARGS "'$CMDS'" $1;
	fi
else
	echo -e "$BOLD$GREEN>>> NO ISSUES FOUND"$NORM
fi
