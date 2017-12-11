#!/bin/bash

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#                                                     #
#                 BPL Commander Script                #
#                by locohammerhead and                #
#           tharude a.k.a The Forging Penguin         #
#         thanks ViperTKD for the helping hand        #
#                 19/01/2017 ARK Team                 #
#                                                     #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#


### Adding some color ###

# Line coloring functions

function red {
        echo -e "$(tput bold; tput setaf 1)$1$(tput sgr0)"
}

function igreen {
	echo -e "$(tput bold; tput setaf 0; tput setab 2)$1$(tput sgr0)"
}

function ired {
	echo -e "$(tput bold; tput setaf 3; tput setab 1)$1$(tput sgr0)"
}

function green {
        echo -e "$(tput bold; tput setaf 2)$1$(tput sgr0)"
}

function yellow {
        echo -e "$(tput bold; tput setaf 3)$1$(tput sgr0)"
}


### Checking if the script is started as root ###

if [ "$(id -u)" = "0" ]; then
	clear
	echo -e "\n$(ired " !!! This script should NOT be started using sudo or as the root user !!! ") "
	echo -e "\nUse $(green "bash BPLcommander.sh") as a REGULAR user instead"
	echo -e "Execute ONCE $(green "chmod +x BPLcommander.sh") followed by $(green "ENTER")"
	echo -e "and start it only by $(green "./bplcommander.sh") as regular user after\n"
	exit 1
fi

### Checking the Virtualization Environment ###

if [ $(systemd-detect-virt -c) != "none" ]; then
	clear
	echo "$(ired "                                                                                 ")"
	echo "$(ired "                    OpenVZ / LXC / Virtuoso Container detected!                  ")"
	echo "$(ired "                                                                                 ")"
	echo "$(ired "     Running BPL Node on a Container based virtual system is not recommended!    ")"
	echo "$(ired "   Please change your VPS provider with one that uses hardware Virtualization.   ")"
	echo "$(ired "                                                                                 ")"
	echo "$(ired "                            This script will now exit!                           ")"
	echo "$(ired "                                                                                 ")"
	exit 1
fi


# TEMP N
# sudo apt-get install npm
# sudo npm install -g n
# sudo n 6.9.2


# ----------------------------------
# Variables
# ----------------------------------

EDIT=nano

GIT_ORIGIN=mainnet

LOC_SERVER="http://localhost:9030"

ADDRESS=""

SNAPDIR="$HOME/snapshots"

re='^[0-9]+$' # For numeric checks

#pubkey="02a3e3e5fc36565ab4275ddfee1592667f6c46f5e9aa7528499511d65c5e82a7db"

# Logfile
log="install_bpl.log"

#~ SEED NODES ~#
seed0=("13.56.163.57:9030" "seed01")
seed1=("54.183.132.15:9030" "seed02")
seed2=("54.183.69.30:9030" "seed03")
seed3=("54.183.152.67:9030" "seed04")
seed4=("54.183.22.145:9030" "seed05")

#~ API CALL ~#
apicall="/api/loader/status/sync"

# ----------------------------------
# Arrays
# ----------------------------------

# Install prereq packages array
declare -a array=("postgresql" "postgresql-contrib" "libpq-dev" "build-essential" "python" "git" "curl" "jq" "libtool" "autoconf" "locales" "automake" "locate" "wget" "zip" "unzip" "htop" "nmon" "iftop")

#~ Network height checker ~#
declare -a nodes=(seed0[@] seed1[@] seed2[@] seed3[@] seed4[@])
declare -a height=()

# Get array length
arraylength=${#nodes[@]}

# ----------------------------------
# Functions
# ----------------------------------

# ASCII Art function
function asciiart {
clear
tput bold; tput setaf 2
cat << "EOF"

                               $$$$$$$\  $$$$$$$\  $$\                                           
                               $$  __$$\ $$  __$$\ $$ |                                          
                               $$ |  $$ |$$ |  $$ |$$ |                                          
                               $$$$$$$\ |$$$$$$$  |$$ |                                          
                               $$  __$$\ $$  ____/ $$ |                                          
                               $$ |  $$ |$$ |      $$ |                                          
 $$$$$$\                       $$$$$$$  |$$ |      $$$$$$$$\             $$\                     
$$  __$$\                      \_______/ \__|      \________|            $$ |                    
$$ /  \__|$$$$$$\  $$$$$$\$$$$\  $$$$$$\$$$$\   $$$$$$\  $$$$$$$\   $$$$$$$ | $$$$$$\   $$$$$$\  
$$ |     $$  __$$\ $$  _$$  _$$\ $$  _$$  _$$\  \____$$\ $$  __$$\ $$  __$$ |$$  __$$\ $$  __$$\ 
$$ |     $$ /  $$ |$$ / $$ / $$ |$$ / $$ / $$ | $$$$$$$ |$$ |  $$ |$$ /  $$ |$$$$$$$$ |$$ |  \__|
$$ |  $$\$$ |  $$ |$$ | $$ | $$ |$$ | $$ | $$ |$$  __$$ |$$ |  $$ |$$ |  $$ |$$   ____|$$ |      
\$$$$$$  \$$$$$$  |$$ | $$ | $$ |$$ | $$ | $$ |\$$$$$$$ |$$ |  $$ |\$$$$$$$ |\$$$$$$$\ $$ |      
 \______/ \______/ \__| \__| \__|\__| \__| \__| \_______|\__|  \__| \_______| \_______|\__|      
                                                                                                 
                                                                                                 
                                                                                                 
                                W E L C O M E  A B O A R D !

EOF
tput sgr0
}

pause(){
        read -p "$(yellow "       Press [Enter] key to continue...")" fakeEnterKey
}

# Current Network Height

function net_height {
	# Spawning curl netheight processes loop
        for n in {1..$arraylength..$arraylength}; do
                for (( i=1; i<${arraylength}+1; i++ )); do
                        saddr=${!nodes[i-1]:0:1}
                        echo $i $(curl -m 3 -s $saddr$apicall | cut -f 5 -d ":" | sed 's/,.*//' | sed 's/}$//') >> $HOME/tout.txt &
                done
                wait
        done

	# Array read
	while read ind line; do
		height[$ind]=$line # assign array values
	done < $HOME/tout.txt
	rm $HOME/tout.txt

	# Finding the highest seednodes block
	IFS=$'\n'
	highest=($(sort -nr <<<"${height[*]}"))
	unset IFS
}

# Find parent PID
function top_level_parent_pid {
        # Look up the parent of the given PID.
        pid=${1:-$$}
	if [ "$pid" != "0" ]; then
	        stat=($(</proc/${pid}/stat))
        	ppid=${stat[3]}

	        # /sbin/init always has a PID of 1, so if you reach that, the current PID is
        	# the top-level parent. Otherwise, keep looking.
	        if [[ ${ppid} -eq 1 ]] ; then
        	        echo ${pid}
        	else
                	top_level_parent_pid ${ppid}
        	fi
	else
		pid=0
	fi
}

# Process management variables
function proc_vars {
        node=`pgrep -a "node" | grep  | awk '{print $1}'`
        if [ "$node" == "" ] ; then
                node=0
        fi

        # Is Postgres running
        pgres=`pgrep -a "postgres" | awk '{print $1}'`

        # Find if forever process manager is runing
        frvr=`pgrep -a "node" | grep forever | awk '{print $1}'`

        # Find the top level process of node
        # Looking for BPL-node installations and performing actions
        bpldir=`locate -b "\BPL-node"`

        # Getting the parent of the install path
        parent=`dirname $bpldir 2>&1`

        # Forever Process ID
        forever_process=`forever --plain list | grep $node | sed -nr 's/.*\[(.*)\].*/\1/p'`

        # Node process work directory
        nwd=`pwdx $node 2>/dev/null | awk '{print $2}'`
}

#PSQL Queries
query() {
PUBKEY="$(psql -d bpl_mainnet -t -c 'SELECT ENCODE("publicKey",'"'"'hex'"'"') as "publicKey" FROM mem_accounts WHERE "address" = '"'"$ADDRESS"'"' ;' | xargs)"
DNAME="$(psql -d bpl_mainnet -t -c 'SELECT username FROM mem_accounts WHERE "address" = '"'"$ADDRESS"'"' ;' | xargs)"
PROD_BLOCKS="$(psql -d bpl_mainnet -t -c 'SELECT producedblocks FROM mem_accounts WHERE "address" = '"'"$ADDRESS"'"' ;' | xargs)"
MISS_BLOCKS="$(psql -d bpl_mainnet -t -c 'SELECT missedblocks FROM mem_accounts WHERE "address" = '"'"$ADDRESS"'"' ;' | xargs)"
#BALANCE="$(psql -d bpl_mainnet -t -c 'SELECT (balance/100000000.0) as balance FROM mem_accounts WHERE "address" = '"'"$ADDRESS"'"' ;' | sed -e 's/^[[:space:]]*//')"
BALANCE="$(psql -d bpl_mainnet -t -c 'SELECT to_char(("balance"/100000000.0), '"'FM 999,999,999,990D00000000'"' ) as balance FROM mem_accounts WHERE "address" = '"'"$ADDRESS"'"' ;' | xargs)"
HEIGHT="$(psql -d bpl_mainnet -t -c 'SELECT height FROM blocks ORDER BY HEIGHT DESC LIMIT 1;' | xargs)"
RANK="$(psql -d bpl_mainnet -t -c 'WITH RANK AS (SELECT DISTINCT "publicKey", "vote", "round", row_number() over (order by "vote" desc nulls last) as "rownum" FROM mem_delegates where "round" = (select max("round") from mem_delegates) ORDER BY "vote" DESC) SELECT "rownum" FROM RANK WHERE "publicKey" = '"'03cfafb2ca8cf7ce70f848456b1950dc7901946f93908e4533aace997c242ced8a'"';' | xargs)"
}

# Stats Address Change
change_address() {
	echo "$(yellow "   Enter your delegate address for Stats")"
	echo "$(yellow "    WITHOUT QUOTES, followed by 'ENTER'")"
	read -e -r -p "$(yellow " :") " inaddress
	while [ ! "${inaddress:0:1}" == "A" ] ; do
		echo -e "\n$(ired "   Enter delegate ADDRESS, NOT the SECRET!")\n"
		read -e -r -p "$(yellow " :") " inaddress
	done
	ADDRESS=$inaddress
#	sed -i "s#\(.*ADDRESS\=\)\( .*\)#\1 "\"$inaddress\""#" $DIR/$BASH_SOURCE
	sed -i "1,/\(.*ADDRESS\=\)/s#\(.*ADDRESS\=\)\(.*\)#\1"\"$inaddress\""#" $DIR/$BASH_SOURCE
}


# Forging Turn
turn() {
	DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#	echo $DIR
#	echo "$BASH_SOURCE"
#	echo "$ADDRESS"
	if [ "$ADDRESS" == "" ] ; then
		change_address
#		echo "$(yellow "   Enter your delegate address for Stats")"
#		echo "$(yellow "    WITHOUT QUOTES, followed by 'ENTER'")"
#		read -e -r -p "$(yellow " :") " inaddress
#		while [ ! "${inaddress:0:1}" == "A" ] ; do
#			echo -e "\n$(ired "   Enter delegate ADDRESS, NOT the SECRET!")\n"
#			read -e -r -p "$(yellow " :") " inaddress
#		done
#		ADDRESS=$inaddress
##		sed -i "s#\(.*ADDRESS\=\)\( .*\)#\1 "\"$inaddress\""#" $DIR/$BASH_SOURCE
#		sed -i "1,/\(.*ADDRESS\=\)/s#\(.*ADDRESS\=\)\(.*\)#\1"\"$inaddress\""#" $DIR/$BASH_SOURCE
	fi
#	pause
while true; do
#	trap : INT
	query
	net_height
	asciiart
	proc_vars
	queue=`curl --connect-timeout 3 -f -s $LOC_SERVER/api/delegates/getNextForgers?limit=51 | jq ".delegates"`
	is_forging=`curl -s --connect-timeout 1 $LOC_SERVER/api/delegates/forging/status?publicKey=$PUBKEY 2>/dev/null | jq ".enabled"`
	is_syncing=`curl -s --connect-timeout 1 $LOC_SERVER/api/loader/status/sync 2>/dev/null | jq ".syncing"`
	pos=0
	for position in $queue
	do
		position=`echo "$position" | tr -d '",'`
		if [[ $PUBKEY == $position ]]; then
#			echo "$position : $pos <=="
			turn=$pos
		fi
		pos=`expr $pos + 1`
	done
	git_upd_check
	echo -e "$(yellow "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")"
	echo -e "$(green "                   NODE STATS")"
	echo -e "$(yellow "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")"
	echo
	echo -e "$(green "      Delegate         : ")$(yellow "$DNAME")"
	echo -e "$(green "      Forging          : ")$(yellow "$is_forging")"
	echo -e "$(green "      Current Rank     : ")$(yellow "$RANK")"
	echo -e "$(green "      Forging Position : ")$(yellow "$turn")"
	echo -e "$(green "      Node Blockheight : ")$(yellow "$HEIGHT")"
	echo -e "$(green "      Net Height       : ")$(yellow "$highest")"
#	echo -e "$(green "Public Key:")\n$(yellow "$PUBKEY")\n"
	echo -e "$(green "      Forged Blocks    : ")$(yellow "$PROD_BLOCKS")"
	echo -e "$(green "      Missed Blocks    : ")$(yellow "$MISS_BLOCKS")"
	echo -e "$(green "      BPL Balance      : ")$(yellow "$BALANCE")"
	echo
	echo -e "\n$(yellow "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")"
        if [ -e $bpldir/app.js ]; then
                echo -e "\n$(green "       ✔ BPL Node installation found!")\n"
                if [ "$node" != "" ] && [ "$node" != "0" ]; then
                        echo -e "$(green "      BPL Node process is running with:")"
                        echo -e "$(green "   System PID: $node, Forever PID $forever_process")"
                        echo -e "$(green "   and Work Directory: $bpldir")\n"
                else
                        echo -e "\n$(red "       ✘ No BPL Node process is running")\n"
                fi
        else
                echo -e "\n$(red "       ✘ No BPL Node installation is found")\n"
        fi
	echo -e "\n$(yellow "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")"
	echo -e "\n$(yellow "          Press 'Enter' to terminate          ")"
	read -t 4 && break

#sleep 4
done
}

# Stats Display
function stats {
	asciiart
	proc_vars
	is_forging=`curl -s --connect-timeout 1 $LOC_SERVER/api/delegates/forging/status?publicKey=$pubkey 2>/dev/null | jq ".enabled"`
	is_syncing=`curl -s --connect-timeout 1 $LOC_SERVER/api/loader/status/sync 2>/dev/null | jq ".syncing"`

	if [ "$node" != "" ] && [ "$node" != "0" ]; then
		echo -e "$(green "       Instance of BPL Node found with:")"
		echo -e "$(green "       System PID: $node, Forever PID $forever_process")"
		echo -e "$(green "       Directory: $bpldir")\n"
	else
		echo -e "\n$(red "       ✘ BPL Node process is not running")\n"
		pause
	fi

}

# Updating the locate database
function db_up {
	echo -e "$(red "Please enter your sudo password for user $USER")"
	sudo updatedb
}

# Update and upgrade the OS
function os_up {
	asciiart
	echo -e "$(yellow "        Checking for system updates...")\n"
	sudo apt-get update >&- 2>&- #-yqq 2>/dev/null
	avail_upd=`/usr/lib/update-notifier/apt-check 2>&1 | cut -d ';' -f 1`
	sec_upd=`/usr/lib/update-notifier/apt-check 2>&1 | cut -d ';' -f 2`
		if [ "$avail_upd" == 0 ]; then
		        echo -e "$(green "        There are no updates available")\n"
		        sleep 1
		else
			echo -e "\n$(red "        There are $avail_upd updates available")"
			echo -e "$(red "        $sec_upd of them are security updates")"
			echo -e "\n$(yellow "            Updating the system...")"
			sudo apt-get upgrade -yqq >&- 2>&- #2>/dev/null
			sudo apt-get dist-upgrade -yq >&- 2>&- #2>/dev/null
			#sudo apt-get purge nodejs postgresql postgresql-contrib samba*
			sudo apt-get autoremove -yyq >&- 2>&- #2>/dev/null
			sudo apt-get autoclean -yq >&- 2>&- #2>/dev/null
			echo -e "\n$(green "          ✔ The system was updated!")"
			echo -e "\n$(red "        System restart is recommended!\n")"
		fi
}

# Install prerequisites
function prereq {
	# Get array length
        arraylength=${#array[@]}

        # Installation loop
        echo -e "$(yellow "-----------------------------------------------")"
        for (( i=1; i<${arraylength}+1; i++ ));
		do
			asciiart;
          		echo -e "$(yellow "         Installing prerequisites...") "
          		echo -e "$(yellow "-----------------------------------------------")" # added
               		echo -e "$(yellow "  $i  /  ${arraylength}  :  ${array[$i-1]}")"
			if [ $(dpkg-query -W -f='${Status}' ${array[$i-1]} 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
                        	sudo apt-get install -yqq >&- 2>&- ${array[$i-1]};
                	else
                        	echo "$(green " Package: ${array[$i-1]} is already installed!")"
                	fi
                	echo -e "$(yellow "-----------------------------------------------")"
		        sleep 0.5
		        clear
		done
}

# Install and set locale
function set_locale {
        # Checking Locale first
        asciiart
        if [ `locale -a | grep ^en_US.UTF-8` ] || [ `locale -a | grep ^en_US.utf8` ] ; then
                echo -e "$(green "     ✔  Locale en_US.UTF-8 is installed")\n"
                echo -e "$(yellow "  Checking if the locale is set in bashrc...")"
                        if `grep -E "(en_US.UTF-8)" $HOME/.bashrc` ; then
                                echo -e "\n$(green "          ✔ bashrc is already set")"
                        else
                                # Setting the bashrc locale
                                echo -e "$(red " ✘ Not set yet. Setting the bashrc locale...")"
                                echo -e "export LC_ALL=en_US.UTF-8" >> $HOME/.bashrc
                                echo -e "export LANG=en_US.UTF-8" >> $HOME/.bashrc
                                echo -e "export LANGUAGE=en_US.UTF-8" >> $HOME/.bashrc
                                echo -e "$(green "           ✔ bashrc locale was set")\n"

                                # Setting the current shell locale
                                echo -e "$(yellow "      Setting current shell locale...")\n"
                                export LC_ALL=en_US.UTF-8
                                export LANG=en_US.UTF-8
                                export LANGUAGE=en_US.UTF-8
                                echo -e "$(green "           ✔ Shell locale was set")"
                        fi
        else
                # Install en_US.UTF-8 Locale
                echo -e "$(red "   ✘ Locale en_US.UTF-8 is not installed")\n"
                echo -e "$(yellow "   Generating locale en_US.UTF-8...")"
                sudo locale-gen en_US.UTF-8
                sudo update-locale LANG=en_US.UTF-8
                echo -e "$(green "    ✔  Locale generated successfully.")\n"

                # Setting the current shell locale
                echo -e "$(yellow "     Setting current shell locale...")\n"
                export LC_ALL=en_US.UTF-8
                export LANG=en_US.UTF-8
                export LANGUAGE=en_US.UTF-8
                echo -e "$(green "         ✔ Shell locale was set")\n"

                # Setting the bashrc locale
                echo -e "$(yellow "   Setting the bashrc locale...")\n"
                echo "export LC_ALL=en_US.UTF-8" >> $HOME/.bashrc
                echo "export LANG=en_US.UTF-8" >> $HOME/.bashrc
                echo "export LANGUAGE=en_US.UTF-8" >> $HOME/.bashrc
                echo -e "$(green "        ✔ bashrc locale was set")"
        fi
}

# Install and set NTP
function ntpd {
        # Check if ve are running in a OpenVZ or LXC Container for NTP Install
        if [ $(systemd-detect-virt) == "lxc" ] || [ $(systemd-detect-virt) == "openvz" ]; then
                echo -e "Your host is running in LXC or OpenVZ container. NTP is not required. \n"
        else
                echo -e "Checking if NTP is running first... \n"
                if ! sudo pgrep -x "ntpd" > /dev/null; then
                        echo -e "No NTP found. Installing... "
                        sudo apt-get install ntp -yyq &>> $log
                        sudo service ntp stop &>> $log
                        sudo ntpd -gq &>> $log
			sleep 2
                        sudo service ntp start &>> $log
			sleep 2
                                if ! sudo pgrep -x "ntpd" > /dev/null; then
                                        echo -e "NTP failed to start! It should be installed and running for BPL.\n Check /etc/ntp.conf for any issues and correct them first! \n Exiting."
                                        exit 1
                                fi
                        echo -e "NTP was successfully installed and started with PID:" `sudo pgrep -x "ntpd"`
                else
                        echo "NTP is up and running with PID:" `sudo pgrep -x "ntpd"`
                fi
        fi
        echo "-------------------------------------------------------------------"
}

# Logrotate for BPL Node logs
function log_rotate {
	if [[ "$(uname)" == "Linux" ]]; then

		if [ ! -f /etc/logrotate.d/BPL-logrotate ]; then
			echo -e " Setting up Logrotate for BPL node log files."
			sudo bash -c "cat << 'EOF' >> /etc/logrotate.d/BPL-logrotate
$BPLdir/logs/BPL.log {
        size=50M
        copytruncate
        create 660 $USER $USER
        missingok
        notifempty
        compress
        delaycompress
        daily
        rotate 7
        dateext
        maxage 7
}
EOF"
		else
			echo -e "$(green "      ✔ Logrotate file already exists!")\n"
		fi
	fi
}

# GIT Update Check
function git_upd_check {

	if [ -d "$bpldir" ]; then

		cd $bpldir

		git remote update >&- 2>&-
		UPSTREAM=${1:-'@{u}'}
		LOCAL=$(git rev-parse @)
		REMOTE=$(git rev-parse "$UPSTREAM")
		BASE=$(git merge-base @ "$UPSTREAM")

		cd $HOME

		if [ "$LOCAL" == "$REMOTE" ]; then
			echo -e "         $(igreen "    BPL Node is Up-to-date    \n")"
			UP_TO_DATE=1
		elif [ "$LOCAL" == "$BASE" ]; then
			echo -e "         $(ired "   Please Update! Press (3)    \n")"
			UP_TO_DATE=0
		else
			echo -e "         $(ired "           Diverged            \n")"
		fi
	fi

}

# Install PostgreSQL
function inst_pgdb {
        sudo apt install -yyq postgresql postgresql-contrib >&- 2>&-
}

# Purge the Postgres Database
function purge_pgdb {
        if [ $(dpkg-query -W -f='${Status}' postgresql } 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
                echo "$(green "  Postgres is not installed, nothing to purge. Exiting.") "
        else
	echo -e "    $(ired "                                        ")"
	echo -e "    $(ired "   WARNING! This option will stop all   ")"
	echo -e "    $(ired "   running BPL Node processes and will  ")"
	echo -e "    $(ired "   remove the databases and PostgreSQL  ")"
	echo -e "    $(ired "   installation! Are you REALLY sure?   ")"
	echo -e "    $(ired "                                        ")"
	read -e -r -p "$(yellow "\n    Type (Y) to proceed or (N) to cancel: ")" -i "N" YN
		if [[ "$YN" =~ [Yy]$ ]]; then
			echo -e "$(yellow "\n     Proceeding with PostgreSQL removal... \n")"
			forever --silent --plain stopall
			sleep 1
			drop_db
			drop_user

        		# stop the DB if running first...
		        sudo service postgresql stop
		        sleep 1
		        sudo apt --purge remove -yq postgresql\* >&- 2>&-
		        sudo rm -rf /etc/postgresql/ >&- 2>&-
		        sudo rm -rf /etc/postgresql-common/ >&- 2>&-
		        sudo rm -rf /var/lib/postgresql/ >&- 2>&-
		        sudo userdel -r postgres >&- 2>&-
		        sudo groupdel postgres >&- 2>&-
			echo -e "$(yellow "\n          PostgreSQL has been removed\n")"

			read -e -r -p "$(yellow "\n  Proceed with PostgreSQL installation (Y/n): ")" -i "Y" YN
			if [[ "$YN" =~ [Yy]$ ]]; then
				echo -e "$(yellow "\n   Proceeding with PostgreSQL installation... \n")"
				inst_pgdb
				create_db
				echo -e "$(yellow "\n    PostgreSQL has been installed and set.\n")"
				pause
			fi
		fi
        fi
}

function snap_menu {
if [ ! -d "$SNAPDIR" ]; then
	mkdir -p $SNAPDIR
fi

if [ "$(ls -A $SNAPDIR)" ]; then
	if [[ $(expr `date +%s` - `stat -c %Y $SNAPDIR/current`) -gt 900 ]]; then
		echo -e "$(yellow " Existing Current snapshot is older than 15 minutes")"
        	read -e -r -p "$(yellow "\n Download from Blockpool.IO? (Y) or use Local (N) ")" -i "Y" YN
			if [[ "$YN" =~ [Yy]$ ]]; then
				echo -e "$(yellow "\n     Downloading latest snapshot from Blockpool.IO\n")"
				rm $SNAPDIR/current
				wget -nv https://snapshots.blockpool.io/current -O $SNAPDIR/current
				echo -e "$(yellow "\n              Download finished\n")"
			fi
	fi

        snapshots=( $(ls -t $SNAPDIR | xargs -0) )
        echo -e "$(yellow "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")"
        echo -e "$(green "           List of local snapshots:")"
        echo -e "$(yellow "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n")"
        for (( i=0; i<${#snapshots[*]}; i++ )); do
                if [ $i -le 9 ]; then
                        echo "             "  $(($i+1)): ${snapshots[$i]}
                else
                        echo "            "  $(($i+1)): ${snapshots[$i]}
                fi
        done

        read -ep "$(yellow "\n       Which snapshot to be restored? ")"
        if [[ "${REPLY}" =~ $re ]]; then
        ## Numeric checks
                if [ $REPLY -le ${#snapshots[*]} ]; then
                        echo -e "$(yellow "\n         Restoring snapshot ${snapshots[$((REPLY-1))]}")\n"
			pg_restore -O -j 8 -d bpl_mainnet $SNAPDIR/${snapshots[$(($REPLY-1))]} 2>/dev/null
			echo -e "$(green "   Snapshot ${snapshots[$(($REPLY-1))]} was restored successfully")\n"
                else
                        echo -e "$(red "\n        Value is out of list range!\n")"
			snap_menu
                fi
        else
                echo -e "$(red "\n             $REPLY is not a number!\n")"
		snap_menu
        fi
else
        echo -e "$(red "    No snapshots found in $SNAPDIR")"
        read -e -r -p "$(yellow "\n Do you like to download the latest snapshot? (Y/n) ")" -i "Y" YN
        if [[ "$YN" =~ [Yy]$ ]]; then
		echo -e "$(yellow "\n     Downloading current snapshot from BPL.IO\n")"
                wget -nv https://snapshots.blockpool.io/current -O $SNAPDIR/current
		echo -e "$(yellow "\n              Download finished\n")"
        fi

        if [[ $? -eq 0 ]]; then
                read -e -r -p "$(yellow "  Do you like to restore the snapshot now? (Y/n) ")" -i "Y" YN
                        if [[ "$YN" =~ [Yy]$ ]]; then
                                #here calling the db_restore function
				echo -e "$(yellow "\n   Restoring $SNAPDIR/current ... ")"
                                pg_restore -O -j 8 -d bpl_mainnet $SNAPDIR/current 2>/dev/null
				echo -e "$(green "\n    Current snapshot has been restored\n")"
                        fi
        else
                echo -e "$(red "\n    Error while retriving the snapshot")"
                echo -e "$(red "  Please check that the file exists on server")"
        fi

fi
}

# Check if program is installed
function node_check {
        # defaulting to 1
        return_=1
        # changing to 0 if not found
        type $1 >/dev/null 2>&1 || { return_=0; }
        # return value
        # echo "$return_"
}

# Install NVM and node
function nvm {
        node_check node
        if [ "$return_" == 0 ]; then
                echo -e "$(red "      ✘ Node is not installed, installing...")"
                curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.32.0/install.sh 2>/dev/null | bash >>install.log
                export NVM_DIR="$HOME/.nvm"
                [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
                ### Installing node ###
                nvm install 6.9.5 >>install.log
                nvm use 6.9.5 >>install.log
                nvm alias default 6.9.5 >>install.log
                echo -e "$(green "      ✔ Node `node -v` has been installed")"
        else
                echo -e "$(green "      ✔ Node `node -v` is  alredy installed")"
        fi

        node_check npm
        if [ "$return_" == 0 ]; then
                echo -e "$(red "      ✘ NPM is not installed, installing...")"
                ### Install npm ###
                npm install -g npm >>install.log 2>&1
                echo -e "$(green "      ✔ NPM `npm -v` has been installed")"
        else
                echo -e "$(green "      ✔ NPM `npm -v` is alredy installed")"
        fi

        node_check forever
        if [ "$return_" == 0 ]; then
                echo -e "$(red "      ✘ Forever is not installed, installing...")"
                ### Install forever ###
                npm install forever -g >>install.log 2>&1
                echo -e "$(green "      ✔ Forever has been installed")"
        else
                echo -e "$(green "      ✔ Forever is alredy installed")"
        fi

        # Setting fs.notify.max_user_watches
        if grep -qi 'fs.inotify' /etc/sysctl.conf ; then
                echo -e "\n$(green "  fs.inotify.max_user_watches is already set")"
        else
                echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
        fi

        echo -e "\n$(yellow "Check install.log for reported install errors")"
}

# Install BPL Node
function inst_bpl {
#	proc_vars
	cd $HOME
        mkdir BPL-node
        git clone https://github.com/blockpool-io/BPL-node.git 2>/dev/null
        cd BPL-node
	git checkout $GIT_ORIGIN 2>/dev/null
	git pull origin $GIT_ORIGIN 2>/dev/null
        npm install grunt-cli -g 2>/dev/null
        npm install libpq 2>/dev/null
        npm install secp256k1 2>/dev/null
        npm install bindings 2>/dev/null
        git submodule init 2>/dev/null
        git submodule update 2>/dev/null
        npm install 2>/dev/null
}

# Create BPL user and DB
function create_db {
        #check if PG is running here if not Start.
        if [ -z "$pgres" ]; then
                sudo service postgresql start
        fi
        sleep 1
#       sudo -u postgres dropdb --if-exists bpl_mainnet
#       sleep 1
#       sudo -u postgres dropuser --if-exists $USER # 2>&1
#       sleep 1
	sudo -u postgres psql -c "update pg_database set encoding = 6, datcollate = 'en_US.UTF8', datctype = 'en_US.UTF8' where datname = 'template0';" >&- 2>&-
	sudo -u postgres psql -c "update pg_database set encoding = 6, datcollate = 'en_US.UTF8', datctype = 'en_US.UTF8' where datname = 'template1';" >&- 2>&-
        sudo -u postgres psql -c "CREATE USER $USER WITH PASSWORD 'password' CREATEDB;" >&- 2>&-
        sleep 1
        createdb bpl_mainnet
}

# Check if DB exists
function db_exists {
        # check if it's running and start if not.
        if [ -z "$pgres" ]; then
                sudo service postgresql start
        fi

        if [[ ! $(sudo -u postgres psql bpl_mainnet -c '\q' 2>&1) ]]; then
                read -r -n 1 -p "$(yellow "  Database exists! Do you want to drop it? (y/n):") " YN
                        if [[ "$YN" =~ [Yy]$ ]]; then
                                drop_db;
                        fi
        else
                echo "Database not exist."
        fi
}

# Check if User exists
function user_exists {
        # check if it's running and start if not.
        if [ -z "$pgres" ]; then
                sudo service postgresql start
        fi

        if [[ $(sudo -u postgres psql postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='$USER'" 2>&1) ]]; then
                echo "User $USER exists";
                read -r -n 1 -p "$(yellow "  User $USER exists! Do you want to remove it? (y/n):") " YN

                        if [[ "$YN" =~ [Yy]$ ]]; then
                                sudo -u postgres dropuser --if-exists $USER
                        fi
        else
                echo "User $USER does not exist"
        fi
}

# Drop BPL DB
function drop_db {
        # check if it's running and start if not.
        if [ -z "$pgres" ]; then
                sudo service postgresql start
        fi
        dropdb --if-exists bpl_mainnet
}

function drop_user {
        if [ -z "$pgres" ]; then
                sudo service postgresql start
        fi

        if [[ $(sudo -u postgres psql postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='$USER'" 2>&1) ]]; then
		sudo -u postgres dropuser --if-exists $USER
        else
                echo "DB User $USER does not exist"
        fi
}

function update_bpl {
	if [ "$UP_TO_DATE" -ne 1 ]; then
	        cd $bpldir
#       	 forever stop app.js
		TMP_PASS=$(jq -r '.forging.secret | @csv' config.$GIT_ORIGIN.json)
		mv config.mainnet.json ../
	        git pull origin $GIT_ORIGIN
		git checkout $GIT_ORIGIN
	        npm install
		sleep 1

		if [ ! -e config.$GIT_ORIGIN.json ]; then
			mv ../config.$GIT_ORIGIN.json .
		else
			jq -r '.forging.secret = ['"$TMP_PASS"']' config.$GIT_ORIGIN.json > config.$GIT_ORIGIN.tmp && mv config.$GIT_ORIGIN.tmp config.$GIT_ORIGIN.json
		fi

		unset TMP_PASS
#		forever restart $forever_process
#	        forever start app.js --genesis genesisBlock.mainnet.json --config config.mainnet.json
	else
		echo "BPL Node is already up to date!"
		sleep 2
	fi
}

# Put the password in config.mainnet.json
function secret {
    echo -e "\n"

    #Put check if bpldir is empty, if it is stays only config.mainnet.json
    echo -e "$(yellow " Enter (copy/paste) your private key (secret)")"
    echo -e "$(yellow "    (WITHOUT QUOTES!) followed by 'Enter'")"
    read -e -r -p ": " secret

    cd $bpldir
    jq -r ".forging.secret = [\"$secret\"]" config.$GIT_ORIGIN.json > config.$GIT_ORIGIN.tmp && mv config.$GIT_ORIGIN.tmp config.$GIT_ORIGIN.json
}

### Menu Options ###

# Install BPL node
one(){
	cd $HOME
	proc_vars
	if [ -e $bpldir/app.js ]; then
		clear
		asciiart
		echo -e "\n$(green "       ✔ BPL Node is already installed!")\n"
		if [ "$node" != "" ] && [ "$node" != "0" ]; then
                	echo -e "$(green "A working instance of BPL Node is found with:")"
                	echo -e "$(green "System PID: $node, Forever PID $forever_process")"
        	        echo -e "$(green "and Work Directory: $bpldir")\n"
                fi
		pause
	else
		clear
		asciiart
		echo -e "$(yellow "           Installing BPL node....")"
		create_db
		inst_bpl
		clear
		asciiart
		echo -e "$(green "          ✔ BPL node was installed")\n"
		sudo updatedb
		sleep 1
		proc_vars
		log_rotate
		config="$parent/config.mainnet.json"
#		echo "$config" 2>/dev/null
#		pause
		if  [ ! -e $config ] ; then
			read -e -r -p "$(yellow " Do you want to set your Secret Key now? (Y/N): ")" -i "Y" keys
			if [ "$keys" == "Y" ]; then
				five
			fi
		fi
	fi
}

# Reinstall BPL Node
two(){
	clear
	asciiart
	echo -e "$(ired "!!! This option will erase your DB and BPL Node installation !!!")\n"
	read -e -r -p "$(red "   Are you sure that you want to proceed? (Y/N): ")" -i "N" keys
	if [ "$keys" == "Y" ]; then
		proc_vars
        	if [ -e $bpldir/app.js ]; then
                	clear
                	asciiart
                	echo -e "\n$(green " ✔ BPL Node installation found in $bpldir")\n"
                	if [ "$node" != "" ] && [ "$node" != "0" ]; then
                        	echo -e "$(green "A working instance of BPL Node is found with:")"
                        	echo -e "$(green "System PID: $node, Forever PID $forever_process")"
				echo -e "$(yellow "           Stopping BPL node ...")\n"
				cd $bpldir
				forever --plain stop $forever_process >&- 2>&-
				cd $parent
                	fi
			echo -e "$(yellow "    Backing up configuration file to $parent")\n"
			sleep 1
			if [ -e $parent/config.mainnet.json ] ; then
				read -e -r -p "$(yellow "    Backup file exists! Overwrite? (Y/N): ")" -i "Y" keys
				if [ "$keys" == "Y" ]; then
					cp $bpldir/config.mainnet.json $parent
					cd $parent
				fi
			else
				cp $bpldir/config.mainnet.json $parent
				cd $parent
			fi
			echo -e "$(yellow "        Removing BPL Node directory...")\n"
			sleep 1
			rm -rf $bpldir
			drop_db
			drop_user
			one
			echo ""
			if [ -e $parent/config.mainnet.json ] ; then
				read -e -r -p "$(yellow " Do you want to restore your config? (Y/N): ")" -i "Y" keys
#				echo "Break1"; pause
				if [ "$keys" == "Y" ]; then
					cp $parent/config.mainnet.json $bpldir
					echo -e "\n$(green " ✔ Config was restored in $bpldir")\n"
					read -e -r -p "$(yellow " Do you want to start BPL Node now? (Y/N): ")" -i "Y" keys
					if [ "$keys" == "Y" ]; then
						start
					fi
				else
					read -e -r -p "$(yellow " Do you want to start BPL Node now? (Y/N): ")" -i "Y" keys
					if [ "$keys" == "Y" ]; then
						start
					fi
				fi
			fi
		else
			echo -e "\n$(green "    ✔ Previous installation not found.")\n"
			drop_db
			drop_user
			sleep 1
			one
			proc_vars
			if [ -e $parent/config.mainnet.json ] ; then
				read -e -r -p "$(yellow " Do you want to restore your config? (Y/N): ")" -i "Y" keys
				if [ "$keys" == "Y" ]; then
					cp $parent/config.mainnet.json $bpldir
					echo -e "\n$(green " ✔ Config was restored in $bpldir")\n"
				fi
			else
				echo -e "\n$(yellow " No backup config was found in $parent")\n"
				read -e -r -p "$(yellow " Do you want to set your Secret Key now? (Y/N): ")" -i "Y" keys
				if [ "$keys" == "Y" ]; then
					secret
				fi
			fi
#			echo "Break2"; pause
			read -e -r -p "$(yellow " Do you want to start BPL Node now? (Y/N): ")" -i "Y" keys
			if [ "$keys" == "Y" ]; then
				start
			fi
		fi
	fi
}

three(){
        asciiart
        proc_vars
	if [ "$UP_TO_DATE" -ne 1 ]; then
	        if [ "$node" != "" ] && [ "$node" != "0" ]; then
        	        echo -e "$(green "       Instance of BPL Node found with:")"
                	echo -e "$(green "       System PID: $node, Forever PID $forever_process")"
	                echo -e "$(green "       Directory: $bpldir")\n"
			echo -e "\n$(green "             Updating BPL Node...")\n"
			update_bpl
	                echo -e "$(green "                Restarting...")"
        	        forever restart $forever_process >&- 2>&-
                	echo -e "\n$(green "    ✔ BPL Node was successfully restarted")\n"
	                pause
		else
                	echo -e "\n$(red "       ✘ BPL Node process is not running")\n"
			echo -e "$(green "            Updating BPL Node...")\n"
			update_bpl
			forever start app.js --genesis genesisBlock.mainnet.json --config config.mainnet.json >&- 2>&-
			echo -e "$(green "    ✔ BPL Node was successfully started")\n"
        	        pause
        	fi
	else
			echo -e "         $(igreen " BPL Node is already Up-to-date \n")"
			sleep 2
	fi

}

four(){
        asciiart
        proc_vars
        if [ "$node" != "" ] && [ "$node" != "0" ]; then
                echo -e "$(green "       Instance of BPL Node found with:")"
                echo -e "$(green "       System PID: $node, Forever PID $forever_process")"
                echo -e "$(green "       Directory: $bpldir")\n"
                echo -e "\n$(green "            Stopping BPL Node...")\n"
		cd $bpldir
		forever stop $forever_process >&- 2>&-
		echo -e "$(green "             Dropping BPL DB...")\n"
                drop_db
		drop_user
		echo -e "$(green "             Creating BPL DB...")\n"
		create_db

		# Here should come the snap choice
		snap_menu
                echo -e "$(green "            Starting BPL Node...")"
		forever start app.js --genesis genesisBlock.mainnet.json --config config.mainnet.json >&- 2>&-
                echo -e "\n$(green "    ✔ BPL Node was successfully started")\n"
                pause
        else
                echo -e "\n$(red "       ✘ BPL Node process is not running")\n"
                echo -e "$(green "             Dropping BPL DB...")\n"
		drop_db
		drop_user
		echo -e "$(green "             Creating BPL DB...")\n"
		create_db

		# Here should come the snap choice
		snap_menu
		echo -e "$(green "            Starting BPL Node...")"
		cd $bpldir
                forever start app.js --genesis genesisBlock.mainnet.json --config config.mainnet.json >&- 2>&-
                echo -e "$(green "    ✔ BPL Node was successfully started")\n"
                pause
        fi
}

five(){
	clear
	asciiart
	proc_vars
	secret
	echo -e "\n$(green "      ✔  Secret has been set/replaced")\n"
	read -e -r -p "$(yellow " Do you want to apply your new config? (Y/N): ")" -i "Y" keys
	if [ "$keys" == "Y" ]; then
        	if [ "$node" != "" ] && [ "$node" != "0" ]; then
			echo -e "\n$(green "       Instance of BPL Node found with:")"
			echo -e "$(green "       System PID: $node, Forever PID $forever_process")"
			echo -e "$(green "       Directory: $bpldir")\n"
			echo -e "$(green "                Restarting...")"
	                forever restart $forever_process >&- 2>&-
			echo -e "\n$(green "    ✔ BPL Node was successfully restarted")\n"
			pause
		else
			echo -e "\n$(red "       ✘ BPL Node process is not running")\n"
			echo -e "$(green "            Starting BPL Node...")\n"
			forever start app.js --genesis genesisBlock.mainnet.json --config config.mainnet.json >&- 2>&-
			echo -e "$(green "    ✔ BPL Node was successfully started")\n"
			pause
		fi
	fi
}

# OS Update
six(){
os_up
pause
}

# Additional Options
seven(){
#nano
while true
do
        asciiart
# HERE COMES THE GITHUB CHECK
        git_upd_check
        sub_menu
        read_sub_options
done

sub_menu
##turn
#pause
}

# Start BPL Node
start(){
        proc_vars
        if [ -e $bpldir/app.js ]; then
                clear
                asciiart
                echo -e "\n$(green "       ✔ BPL Node installation found!")\n"
                if [ "$node" != "" ] && [ "$node" != "0" ]; then
                        echo -e "$(green " A working instance of BPL Node was found with:")"
                        echo -e "$(green "   System PID: $node, Forever PID $forever_process")"
                        echo -e "$(green "   and Work Directory: $bpldir")\n"
		else
			echo -e "$(green "            Starting BPL Node...")\n"
			cd $bpldir
			forever start app.js --genesis genesisBlock.mainnet.json --config config.mainnet.json >&- 2>&-
			cd $parent
			echo -e "$(green "    ✔ BPL Node was successfully started")\n"
			sleep 1
			proc_vars
			echo -e "\n$(green "       BPL Node started with:")"
			echo -e "$(green "   System PID: $node, Forever PID $forever_process")"
			echo -e "$(green "   and Work Directory: $bpldir")\n"
                fi
	else
		echo -e "\n$(red "       ✘ No BPL Node installation is found")\n"
	fi
pause
}

# Node Status
status(){
        proc_vars
        if [ -e $bpldir/app.js ]; then
                clear
                asciiart
                echo -e "\n$(green "       ✔ BPL Node installation found!")\n"
                if [ "$node" != "" ] && [ "$node" != "0" ]; then
                        echo -e "$(green "      BPL Node process is working with:")"
                        echo -e "$(green "   System PID: $node, Forever PID $forever_process")"
                        echo -e "$(green "   and Work Directory: $bpldir")\n"
                else
                        echo -e "\n$(red "       ✘ No BPL Node process is running")\n"
                fi
        else
                echo -e "\n$(red "       ✘ No BPL Node installation is found")\n"
        fi
pause
}

restart(){
	asciiart
	proc_vars
	if [ "$node" != "" ] && [ "$node" != "0" ]; then
                echo -e "$(green "       Instance of BPL Node found with:")"
                echo -e "$(green "       System PID: $node, Forever PID $forever_process")"
                echo -e "$(green "       Directory: $bpldir")\n"
		echo -e "$(green "                Restarting...")"
		forever restart $forever_process >&- 2>&-
		echo -e "\n$(green "    ✔ BPL Node was successfully restarted")\n"
		pause
	else
		echo -e "\n$(red "       ✘ BPL Node process is not running")\n"
		pause
	fi
}

# Stop Node
killit(){
        proc_vars
        if [ -e $bpldir/app.js ]; then
                clear
                asciiart
                echo -e "\n$(green "       ✔ BPL Node installation found!")\n"
                if [ "$node" != "" ] && [ "$node" != "0" ]; then
                        echo -e "$(green " A working instance of BPL Node was found with:")"
                        echo -e "$(green "   System PID: $node, Forever PID $forever_process")"
                        echo -e "$(green "   and Work Directory: $bpldir")\n"
			echo -e "$(green "            Stopping BPL Node...")\n"
			cd $bpldir
			forever stop $forever_process >&- 2>&-
			cd $parent
			echo -e "$(green "    ✔ BPL Node was successfully stopped")\n"
                else
			echo -e "\n$(red "       ✘ No BPL Node process is running")\n"
                fi
        else
                echo -e "\n$(red "       ✘ No BPL Node installation is found")\n"
        fi
pause
}

# Logs
log(){
	clear
	echo -e "\n$(yellow " Use Ctrl+C to return to menu")\n"
	proc_vars
	trap : INT
	tail -f $bpldir/logs/bpl.log
#pause
}

subfive(){
        clear
	asciiart
	purge_pgdb

}

subsix(){
        clear
        asciiart
        change_address

}



# Menu
show_menus() {
	tput bold; tput setaf 3
	echo "         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo "                  O P T I O N S"
	echo "         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo
	echo "              1. Install BPL"
	echo "              2. Reinstall BPL"
	echo "              3. Update BPL"
	echo "              4. Rebuild Database"
	echo "              5. Set/Reset Secret"
	echo "              6. OS Update"
	echo "              7. Additional options"
	echo
	echo "         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo
	echo "              A. BPL Start"
	echo "              R. Restart BPL"
	echo "              K. Kill BPL"
	echo "              S. Node Status"
        echo "              L. Node Log"
	echo "              0. Exit"
	echo
	tput sgr0
}

# Sub Menu
sub_menu() {
	tput bold; tput setaf 3
	echo "         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo "               Additional Options"
	echo "         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo
	echo "           1. Install BPL Cli"
	echo "           2. Install BPL Explorer"
	echo "           3. Install Snapshot script"
	echo "           4. Install Restart script"
	echo "           5. Purge PostgeSQL"
	echo "           6. Replace Delegate Address"
	echo "           0. Exit to Main Manu"
	echo
	echo "         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo
	tput sgr0
}

read_options(){
	local choice
	read -p "        Enter choice [1 - 7,A,R,K,S,L]: " choice
	case $choice in
		1) one ;;
		2) two ;;
		3) three ;;
		4) four ;;
		5) five ;;
		6) six ;;
		7) seven ;;
		A) start ;;
		R) restart ;;
		K) killit;;
		[sS]) turn;;
		[lL]) log;;
		0) exit 0;;
		*) echo -e "$(red "             Incorrect option!")" && sleep 1
	esac
}


read_sub_options(){
	local choice1
	read -p "          Enter choice [1 - 7]: " choice1
	case $choice1 in
		1) subone ;;
		2) subtwo ;;
		3) subthree ;;
		4) four ;;
		5) subfive ;;
		6) subsix ;;
		7) seven ;;
		0) break ;;
		*) echo -e "$(red "             Incorrect option!")" && sleep 1
	esac
}






# ----------------------------------------------
# Trap CTRL+C, CTRL+Z and quit singles
# ----------------------------------------------
trap '' SIGINT SIGQUIT SIGTSTP


# ----------------------------------------------
# First Run Initial OS update and prerequisites
# ----------------------------------------------
if [ -e ./.firstrun ] ; then
	sdate=$(date +"%Y%m%d")
	fdate=$(date +"%Y%m%d")
else
	fdate=$(date -r ./.firstrun +"%Y%m%d")
fi

if [ -e ./.firstrun ] && [ "$fdate" <  "$sdate" ]; then
#       if [ -e ./.firstrun ] && [ $(date -r ./.firstrun +"%Y%m%d") <  $(date +"%Y%m%d") ]; then
                echo -e "$(yellow "      Checking for system updates...")\n"
                os_up
		log_rotate
                touch ./.firstrun
fi

if [ -e ./.firstrun ] && [ "$fdate" =  "$sdate" ]; then
	clear
	asciiart
	echo -e "$(green "         ✔ Your system is up to date.")\n"
else
	if [ ! -e ./.firstrun ] ; then
		clear
		asciiart
		db_up
		clear
		asciiart
		######echo ""
		echo -e "$(yellow "It's the first time you are starting this script!") "
		echo -e "$(yellow "First it will check if your system is up to date") "
		echo -e "$(yellow "install updates and needed prerequisites")\n"
		echo -e "$(yellow "Please be patient! It can take up to 5 minutes!")\n"
		pause
		os_up
		clear
		asciiart
		sleep 1
		node_check iftop
		        if [ "$return_" == 0 ]; then
				echo -e "$(yellow "         Installing prerequisites...") "
				prereq
			else
				echo -e "$(green "    ✔ Prerequisites are already installed")"
			fi
		clear
		asciiart
		echo -e "$(yellow "        Setting up NTP and Locale...") "
		sleep 1
		echo ""
		ntpd
		echo ""
		set_locale
		clear
		asciiart
		echo -e "$(yellow "       Setting up NodeJS environment...") "
		sleep 1
		nvm
		sleep 5
		touch ./.firstrun
		echo -e "\n$(ired "    !!!  PLEASE REBOOT YOUR SYSTEM NOW  !!!    ") "
		  echo -e "$(ired "    !!!   START THIS SCRIPT AGAIN AND   !!!    ") "
		  echo -e "$(ired "    !!!  CHOOSE '1' TO INSTALL BPL NODE !!!    ") "
		exit
	fi
fi

sudo updatedb
proc_vars
#exit

# ----------------------------------------------
# Menu infinite loop
# ----------------------------------------------

while true
do
	asciiart
# HERE COMES THE GITHUB CHECK
	git_upd_check
	show_menus
	read_options
done
