#!/bin/bash
# blatt - (Gentoo) build log arch testing tool
# by Denis M. (Phr33d0m)

CMD_GREP=`command -v egrep`
CMD_GREP_ARGS="--color=always"

CMDS=""
CMDS_ALT=""
ISSUES=""
PKG_NAME=""


### COLOURS
#
TXTRED='\e[0;31m' 		# Red
TXTGRN='\e[0;32m' 		# Green
TXTYLW='\e[0;33m' 		# Yellow
BLDRED='\e[1;31m' 		# Bold Red
BLDGRN='\e[1;32m' 		# Bold Green
BLDYLW='\e[1;33m' 		# Bold Yellow


#checks
if [ $# -ne 1 ]; then
    echo "Usage: $(basename $0) /path/to/logs-dir/<cat>:<pkg>-<ver>-....log"
    exit 1
else
    if [ -f $1 ]; then
	PKG_NAME=`echo $1 | xargs -n 1 basename | sed 's/:/\//;s/:.*//;s/\(.*\)-[0-9]\..*/\1/'`
    else
	echo "ERROR: File does not exist."
	exit 1
    fi
fi



### HARDCODED CALLS
#
for i in $(ls --color=none /usr/bin/x86_64-pc-linux-gnu-* | sed 's:/usr/bin/x86_64-pc-linux-gnu-::g'); do
    CMDS+="^"$i" |";
    CMDS_ALT+="libtool.* "$i"|";
done

#sanitize vars
CMDS=$(sed 's:|$::' <<< $CMDS)
CMDS_ALT=$(sed 's:|$::' <<< $CMDS_ALT)

CMDS=$(echo $CMDS | sed 's:\+:\\+:g;s:\-:\\-:g')
CMDS_ALT=$(echo $CMDS_ALT | sed 's:\+:\\+:g;s:\-:\\-:g')

if [[ `$CMD_GREP $CMD_GREP_ARGS "'$CMDS'" $1 | wc -l` -gt 0 ]]; then
    ISSUES="${ISSUES} hardcalls-issue"
fi

if [[ `$CMD_GREP $CMD_GREP_ARGS "'$CMDS_ALT'" $1 | wc -l` -gt 0 ]]; then
    ISSUES="${ISSUES} hardcalls-issue"
fi



### USE=static-libs CHECK
#




### MAIN STORY
#
if [[ `echo $ISSUES | grep -c 'issue'` -gt 0 ]]; then
    echo -e $BLDRED">>> ISSUES FOUND!"
    if echo $ISSUES | grep -q 'hardcalls-issue'; then
	echo -e $BLDYLW"> Hardcoded calls:"
	$CMD_GREP $CMD_GREP_ARGS "'$CMDS'" $1
	$CMD_GREP $CMD_GREP_ARGS "'$CMDS_ALT'" $1
    fi
else
    echo -e $BLDGRN">>> NO ISSUES FOUND"
fi
