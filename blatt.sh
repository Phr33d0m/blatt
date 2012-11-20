#!/usr/bin/env bash
# blatt - (Gentoo) build log arch testing tool
# by Denis M. (Phr33d0m)
#    Wyatt Epp

ARGCOUNT=1
E_NOFILE=1
E_WIP=2
E_FLAGSARETOUCHING=4
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
ISSUES=0
HARDCALLS=0
STATIC_REFUGEES=0
RODNEY_DANGERFFLAG=0 #No respect, I tell ya!
VFLAG_O=0
VFLAG_G=0
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
	ATOM=($(qatom $(head -1 $1|sed 's/.*:[[:space:]]*//')))
	CAT=${ATOM[0]}
	PN=${ATOM[1]}
	PV=${ATOM[2]}
	PACKAGE=$CAT/$PN-$PV
}

### HARDCODED CALLS
#TODO: Move this pile of stuff into a function so it only runs if necessary.
# Set up our grep command
for i in $(ls --color=never /usr/bin/x86_64-pc-linux-gnu-* | sed 's:/usr/bin/x86_64-pc-linux-gnu-::g'); do
	CMDS+="^"$i"[[:space:]]|";
	CMDS_ALT+="libtool.* "$i"|";
done
CMDS=${CMDS%?} #Slice off last character
CMDS_ALT=${CMDS_ALT%?} #Slice off last character
# Escape +- for safety
CMDS=$(echo $CMDS | sed 's:\+:\\+:g;s:\-:\\-:g')
CMDS_ALT=$(echo $CMDS_ALT | sed 's:\+:\\+:g;s:\-:\\-:g')

function hardcalls(){ # 1: filename 2: PACKAGE
	if [[ $PN == "gvim" ]];then
		echo -e $RED"gvim has issues and will screw with your terminal"
		echo -e $BOLD"TODO: continue ignoring gvim's logs. Do it manually."$NORM
		return
	fi
	TREACLE=$($CMD_GREP $CMD_GREP_ARGS "$CMDS" $1)
	if [[ $TREACLE ]]; then
		let HARDCALLS++
	fi
}

### CHECK: STATIC LIBS
#
function lafiles(){
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
	#TODO: Patch log output to have this (or ask Zac)
	CFLAGS=$(portageq envvar CFLAGS)
	CXXFLAGS=$(portageq envvar CXXFLAGS)
	if [[ $CFLAGS == $CXXFLAGS ]]; then
		echo -e $BOLD$RED"CFLAGS and CXXFLAGS must not match!"$NORM
		return
	else
		RANGE=$(egrep -i "?*x86_64.*-g[++,cc].*\.c?*$" $1) #Filter out all noise
		#TODO: This is painfully naive.
		FLAGSPAM=$($CMD_GREP -v "x86_64.*-gcc.*$CFLAGS|x86_64.*-g++.*$CXXFLAGS" <(echo "$RANGE") )

		# Horrifying magic: remove the C{,XX}FLAGS with variable parameter substitution
		grep -lq "gcc" <(echo "$RANGE") && RANGE=${RANGE//$CFLAGS//}
		grep -lq "g++" <(echo "$RANGE") && RANGE=${RANGE//$CXXFLAGS//}
		VFLAG_G=$(egrep -c " -g " <(echo "$RANGE"))
		VFLAG_O=$(egrep -c " -O[[:digit:],s]" <(echo "$RANGE"))

		if [[ $FLAGSPAM || $(($VFLAG_G + $VFLAG_O)) -ne 0 ]]; then
			let RODNEY_DANGERFFLAG++
		fi
	fi
}

### MAIN STORY
### Call requested tests on each desired file
#TODO: convert to getopts and optional running
for I in $*; do
	if [[ -d $I || ! -e $I ]]; then  continue; fi #Skip directories and non-files
	if [[ $( head -1 $I|grep '^No package.*') ]]; then  continue; fi #Skip uninstalls
	atomise $I
	case $DOSTUFF in #This is awful right now. More for structure
		'hardcalls'|'all')
			hardcalls $I
			;;&
		'lafiles'|'all')
			lafiles $I
			;;&
		'flagrespect'|'all')
			flagrespect $I
			;;
		?) # should be unreachable right now.
			exit 0
	esac

	# Can just keep attaching things as tests get added.
	# Any non-negative value makes the if resolve true.
	ISSUES=$(( $HARDCALLS+ \
	           $STATIC_REFUGEES+ \
	           $RODNEY_DANGERFFLAG ))

#TODO: Make per-package report files
	if [[ $ISSUES -gt 0 ]]; then
		echo -e $BOLD$RED">>> $PACKAGE: ISSUES FOUND"
		if [[ $HARDCALLS -gt 0 ]]; then
			echo -e $BOLD$YELLOW"> Hardcoded calls:"$NORM
			echo -e "$TREACLE"$NORM
			HARDCALLS=0
		fi
		if [[ $STATIC_REFUGEES -gt 0 ]]; then
			echo -e $BOLD$YELLOW"> Static libraries (that should not be there) found:"$NORM
			echo -e "$LAFF"
			STATIC_REFUGEES=0
		fi
		if [[ $RODNEY_DANGERFFLAG -gt 0 ]]; then
			if [[ $FLAGSPAM ]]; then
				echo -e $BOLD$YELLOW"> Not respecting CFLAGS/CXXFLAGS:"$NORM
				echo -e "$FLAGSPAM"
			fi
			if [[ $VFLAG_G ]]; then
				echo -e "Added -g "$VFLAG_G" times!"
				VFLAG_G=0
			fi
			if [[ $VFLAG_O ]]; then
				echo -e "Added -O "$VFLAG_O" times!"
				VFLAG_O=0
			fi
			RODNEY_DANGERFFLAG=0
		fi
	else
		echo -e $BOLD$GREEN">>> $PACKAGE: NO ISSUES FOUND"$NORM
	fi
done


