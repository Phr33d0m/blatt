#!/usr/bin/env bash
# blatt - (Gentoo) build log arch testing tool
# by Denis M. (Phr33d0m)

ARGCOUNT=1
E_NOFILE=1
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

#Takes: Filename / Sets: CAT,PN,PV,PACAKGE
function atomise(){
	ATOM=($(qatom `basename $1|sed 's/:/\//;s/:.*//'`))
	CAT=${ATOM[0]}
	PN=${ATOM[1]}
	PV=${ATOM[2]}
	PACKAGE=$CAT/$PN-$PV
}

### HARDCODED CALLS
#TODO: Move this pile of stuff into a function so it only runs if necessary.
# Set up our grep command
for i in $(ls --color=never /usr/bin/x86_64-pc-linux-gnu-* | sed 's:/usr/bin/x86_64-pc-linux-gnu-::g'); do
	CMDS+="^"$i" |";
	CMDS_ALT+="libtool.* "$i"|";
done
CMDS=${CMDS%?} #Slice off last character
CMDS_ALT=${CMDS_ALT%?} #Slice off last character
# Escape +- for safety
CMDS=$(echo $CMDS | sed 's:\+:\\+:g;s:\-:\\-:g') 
CMDS_ALT=$(echo $CMDS_ALT | sed 's:\+:\\+:g;s:\-:\\-:g')

function hardcalls(){ # 1: filename 2: PN
	HARDCALLS=0 #Boolean
	TREACLE=$($CMD_GREP $CMD_GREP_ARGS "$CMDS" $1)
	if [[ $TREACLE ]]; then
		I_HARDCALLPN=("${I_HARDCALLPN[@]}" "$2")
		I_HARDCALL_LINES=("${I_HARDCALL_LINES[@]}" "$TREACLE")
		let HARDCALLS++
	else
		echo -e $GREEN$2" is clean"$NORM
	fi
}

### CHECK: STATIC LIBS
#
function lafiles(){
	STATIC_REFUGEES=0
	if [[ $(head -4 $1|grep "USE.*static-libs") ]]; then
		return # The USEs in the log are build-time
	else
		LAFF=$(qlist -C $PACKAGE|$CMD_GREP '.*\.a$|.*\.la$')
		if [[ $LAFF ]]; then
			let STATIC_REFUGEES++
		fi
	fi
}

### CHECK: CFLAGS/CXXFLAGS respect
#
function flagrespect(){
	echo "flagrespect() Work in progress"
}

### MAIN STORY
### Call requested tests on each desired file
#TODO: convert to getopts and optional running
for I in $*; do
	if [[ -d $I ]]; then  continue; fi #Skip directories
	atomise $I
	case $DOSTUFF in #This is awful right now. More for structure
		'hardcalls'|'all')
			hardcalls $I $PACKAGE
			;;&
		'lafiles'|'all')
			lafiles $I $PACKAGE
			;;&
		'flagrespect'|'all')
			#flagrespect $I $PACKAGE
			;;
		?) # should be unreachable right now.
			exit 0
	esac

	ISSUES=$(( $HARDCALLS+$STATIC_REFUGEES )) # Can just keep attaching things as tests get added. 
	                                          # Any non-negative value makes the if resolve true.

#TODO: Make per-package report files
	if [[ $ISSUES -gt 0 ]]; then
		echo -e $BOLD$RED">>> $PACKAGE: ISSUES FOUND"
		if [[ $HARDCALLS -gt 0 ]]; then
			echo -e $BOLD$YELLOW"> Hardcoded calls:"$NORM
			for ((I=0; I<=$HARDCALLS; I++ )); do
				echo "${I_HARDCALL_LINES[$I]}"
			done
		fi
		if [[ $STATIC_REFUGEES -gt 0 ]]; then
			echo -e $BOLD$YELLOW"> Static Archive Refugees:"$NORM
			echo -e "$LAFF"
		fi
	else
		echo -e "$BOLD$GREEN>>> $PACKAGE: NO ISSUES FOUND"$NORM
	fi
done


