#!/usr/bin/env bash
# blatt - (Gentoo) build log arch testing tool
# by Denis M. (Phr33d0m)

CMD_GREP=$(command -v egrep)
CMD_GREP_ARGS="-i --color=always"

CMDS=""
ISSUES=""



### COLOURS

TXTRED='\e[0;31m' 		# Red
TXTGRN='\e[0;32m' 		# Green
TXTYLW='\e[0;33m' 		# Yellow
BLDRED='\e[1;31m' 		# Bold Red
BLDGRN='\e[1;32m' 		# Bold Green
BLDYLW='\e[1;33m' 		# Bold Yellow



### HARDCODED CALLS

for i in $(ls --color=never /usr/bin/x86_64-pc-linux-gnu-* | sed 's:/usr/bin/x86_64-pc-linux-gnu-::g'); do
    CMDS+="^"$i" |";
done

CMDS=$(sed 's:|$::' <<< $CMDS)

if [[ $($CMD_GREP $CMD_GREP_ARGS '"$CMDS"' $1) ]]; then
    ISSUES+=" hardcalls"
fi



### MAIN STORY

if [[ $ISSUES ]]; then
    echo -e "$BLDRED>>> ISSUES FOUND!"
    if echo $ISSUES | grep -q 'hardcalls'; then
	echo -e "$BLDYLW> Hardcoded calls:"
	$CMD_GREP $CMD_GREP_ARGS "'$CMDS'" $1;
    fi
else
    echo -e "$BLDGRN>>> NO ISSUES FOUND"
fi
