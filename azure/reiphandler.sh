#!/usr/bin/env bash
#reip_handler.sh


# chkconfig: 345 99 10
# description: Script to run a on start up and perform re-ip if needed

LOCKFILE=/var/lock/subsys/reiphandler
PROCESS_LOG_FILE=-target-folder-reip_handler.log
ONE_TIME_FILE=-target-folder-drctexecflag

start(){
    # Touch our lock file so that stopping will work correctly
	touch ${LOCKFILE}
    VERSION=$(rpm -q --queryformat '%{VERSION}' $(rpm -qa '(redhat|sl|slf|centos|oraclelinux)-release(|-server|-workstation|-client|-computenode)'))

    HV_RESPONSE=$(dmidecode | grep -i -E 'Microsoft')
    #IS_NM_INSTALLED=$(service NetworkManager status | grep 'active')

    IS_RUN_WITHIN_VCENTER=${#HV_RESPONSE}
    if [ $IS_RUN_WITHIN_VCENTER -gt 0 ];
    then

            FULL_PATH=/etc/sysconfig/network-scripts/
            echo $(date -u)' Creating network scripts backup' >> $PROCESS_LOG_FILE
            tar -zcvf /etc/reip/networkscripts.tar.gz $FULL_PATH
            tar -zcvf /etc/reip/rules.tar.gz /etc/udev/rules.d/
            tar -zcvf /etc/reip/network.tar.gz /etc/sysconfig/network


            if [ -f /etc/udev/rules.d/70-persistent-net.rules ];
            then
                rm -rf /etc/udev/rules.d/70-persistent-net.rules
                rm -rf /lib/udev/rules.d/75-persistent-net-generator.rules
                #reboot
            fi

            IS_IFNAMES_KICKED=$(cat /etc/default/grub | grep -E  'net.ifnames=0')
            if [ ${#IS_IFNAMES_KICKED} -eq 0 ];
            then
                echo $(date -u)' GRUB_CMDLINE_LINUX="net.ifnames=0"' >>/etc/default/grub
            fi

            CONFIG_FILES=$(ls $FULL_PATH -I "ifcfg-lo" | grep "ifcfg*")
            INDEX=0
            echo $(date -u)' Renaming all configuration not fits ethX standard' >> $PROCESS_LOG_FILE
            SOURCE_DATA_FILE_PATH=/etc/reip/dhcp.conf
            for CONFIG_FILE in $CONFIG_FILES
            do
                 echo $(date -u)' '$CONFIG_FILE >> $PROCESS_LOG_FILE

                SOURCE_PATH=$FULL_PATH$CONFIG_FILE
                TARGET_PATH=$FULL_PATH'ifcfg-eth'$INDEX
                echo $(date -u) ' Source file:'$SOURCE_PATH >> $PROCESS_LOG_FILE
                echo $(date -u) ' Target file:'$TARGET_PATH >> $PROCESS_LOG_FILE

                mv $SOURCE_PATH $TARGET_PATH

                cat $SOURCE_DATA_FILE_PATH > $TARGET_PATH
                INDEX=$((INDEX + 1))
            done

            echo $(date -u)' ReIP handler watchdog started' >> $PROCESS_LOG_FILE
            IS_NETWORK_RESTART_REQUIRED=""
            echo $(date -u)' We're not in VC. May be AWS. Let's give it a chance. Continue processing...' >> $PROCESS_LOG_FILE
            echo $(date -u)' Checking for static IP configuration' >> $PROCESS_LOG_FILE
            CONFIG_FILE_PATTERN=/etc/sysconfig/network-scripts/ifcfg-eth*

            COMMON_NETWORK_FILE=/etc/sysconfig/network
            echo $(date -u)' Processing GATEWAY section by removing it if exists' >> $PROCESS_LOG_FILE
            TMP=$(cat $COMMON_NETWORK_FILE | grep -v GATEWAY)
            echo $TMP > $COMMON_NETWORK_FILE

            for CONFIG_FILE_PATH in $CONFIG_FILE_PATTERN
            do
                echo $(date -u)' Starting test for file '$CONFIG_FILE_PATH >> $PROCESS_LOG_FILE
                IS_STATIC_IP=$(cat $CONFIG_FILE_PATH | grep -E  'BOOTPROTO=static|BOOTPROTO=none')
                echo $(date -u)' Static ip test returned '$IS_STATIC_IP >> $PROCESS_LOG_FILE
                if [ ! -z $IS_STATIC_IP ];
                then
                    echo $(date -u)" Static IP configuration discovered" >> $PROCESS_LOG_FILE
                    echo $(date -u)" Processing "$CONFIG_FILE_PATH" file" >> $PROCESS_LOG_FILE
                    FILE_NAME=$(basename $CONFIG_FILE_PATH)
                    INTERFACE_NAME=${FILE_NAME#"ifcfg-"}
                    INTERFACE_NAME=${INTERFACE_NAME%"ifcfg-"}
                    echo $(date -u)" Interface name "$INTERFACE_NAME" extracted" >> $PROCESS_LOG_FILE
                    # EDIT instead of replace
                    echo $(date -u)" Updating configuration file" >> $PROCESS_LOG_FILE
                    #CONFIG_FILE_PATH=/home/ec2-user/data.txt

                    echo $(date -u)" Processing DEVICE section">> $PROCESS_LOG_FILE
                    OLD_VALUE=$(cat $CONFIG_FILE_PATH | grep DEVICE)
                    NEW_VALUE='DEVICE="'$INTERFACE_NAME'"'
                    if [ ! -z $OLD_VALUE ];
                    then
                        sed -i -e "s|$OLD_VALUE|$NEW_VALUE|" $CONFIG_FILE_PATH
                    fi
                    cat $CONFIG_FILE_PATH>> $PROCESS_LOG_FILE

                    echo $(date -u)" Processing NAME section">> $PROCESS_LOG_FILE
                    OLD_VALUE=$(cat $CONFIG_FILE_PATH | grep NAME)
                    NEW_VALUE='NAME="'$INTERFACE_NAME'"'
                    if [ ! -z $OLD_VALUE ];
                    then
                        sed -i -e "s|$OLD_VALUE|$NEW_VALUE|" $CONFIG_FILE_PATH
                    fi
                    cat $CONFIG_FILE_PATH>> $PROCESS_LOG_FILE

                    echo $(date -u)" Processing BOOTPROTO section">> $PROCESS_LOG_FILE
                    OLD_VALUE=$(cat $CONFIG_FILE_PATH | grep BOOTPROTO)
                    NEW_VALUE='BOOTPROTO="dhcp"'
                    if [ ! -z $OLD_VALUE ];
                    then
                        sed -i -e "s|$OLD_VALUE|$NEW_VALUE|" $CONFIG_FILE_PATH
                    fi
                    cat $CONFIG_FILE_PATH>> $PROCESS_LOG_FILE

                    echo $(date -u)" Processing ONBOOT section">> $PROCESS_LOG_FILE
                    OLD_VALUE=$(cat $CONFIG_FILE_PATH | grep ONBOOT)
                    NEW_VALUE='ONBOOT="yes"'
                    if [ ! -z $OLD_VALUE ];
                    then
                        sed -i -e "s|$OLD_VALUE|$NEW_VALUE|" $CONFIG_FILE_PATH
                    fi
                    cat $CONFIG_FILE_PATH>> $PROCESS_LOG_FILE

                    echo $(date -u)" Processing TYPE section">> $PROCESS_LOG_FILE
                    OLD_VALUE=$(cat $CONFIG_FILE_PATH | grep TYPE)
                    NEW_VALUE='TYPE="Ethernet"'
                    if [ ! -z $OLD_VALUE ];
                    then
                        sed -i -e "s|$OLD_VALUE|$NEW_VALUE|" $CONFIG_FILE_PATH
                    fi
                    cat $CONFIG_FILE_PATH>> $PROCESS_LOG_FILE

                    echo $(date -u)" Processing USERCTL section">> $PROCESS_LOG_FILE
                    OLD_VALUE=$(cat $CONFIG_FILE_PATH | grep USERCTL)
                    NEW_VALUE='USERCTL="yes"'
                    if [ ! -z $OLD_VALUE ];
                    then
                        sed -i -e "s|$OLD_VALUE|$NEW_VALUE|" $CONFIG_FILE_PATH
                    fi
                    cat $CONFIG_FILE_PATH>> $PROCESS_LOG_FILE

                    echo $(date -u)" Processing IPV6INIT section">> $PROCESS_LOG_FILE
                    OLD_VALUE=$(cat $CONFIG_FILE_PATH | grep IPV6INIT)
                    NEW_VALUE='IPV6INIT="no"'
                    if [ ! -z $OLD_VALUE ];
                    then
                        sed -i -e "s|$OLD_VALUE|$NEW_VALUE|" $CONFIG_FILE_PATH
                    fi
                    cat $CONFIG_FILE_PATH>> $PROCESS_LOG_FILE

                    echo $(date -u)" Processing NM_CONTROLLED section">> $PROCESS_LOG_FILE
                    OLD_VALUE=$(cat $CONFIG_FILE_PATH | grep NM_CONTROLLED=yes)
                    NEW_VALUE='NM_CONTROLLED=no"'
                    if [ ! -z $OLD_VALUE ];
                    then
                        sed -i -e "s|$OLD_VALUE|$NEW_VALUE|" $CONFIG_FILE_PATH
                    fi
                    cat $CONFIG_FILE_PATH>> $PROCESS_LOG_FILE

                    echo $(date -u)" Processing PERSISTENT_DHCLIENT section">> $PROCESS_LOG_FILE
                    echo 'PERSISTENT_DHCLIENT="1"' >> $CONFIG_FILE_PATH
                    cat $CONFIG_FILE_PATH>> $PROCESS_LOG_FILE

                    echo $(date -u)" Processing GATEWAY section by removing it if exists">> $PROCESS_LOG_FILE
                    OLD_VALUE=$(cat $CONFIG_FILE_PATH | grep GATEWAY)
                    NEW_VALUE=''
                    if [ ! -z $OLD_VALUE ];
                    then
                        sed -i -e "s|$OLD_VALUE|$NEW_VALUE|" $CONFIG_FILE_PATH
                    fi
                    cat $CONFIG_FILE_PATH>> $PROCESS_LOG_FILE

                    echo $(date -u)" Processing HWADDR section by removing it if exists">> $PROCESS_LOG_FILE
                    OLD_VALUE=$(cat $CONFIG_FILE_PATH | grep HWADDR)
                    NEW_VALUE=''
                    if [ ! -z $OLD_VALUE ];
                    then
                        sed -i -e "s|$OLD_VALUE|$NEW_VALUE|" $CONFIG_FILE_PATH
                    fi
                    cat $CONFIG_FILE_PATH>> $PROCESS_LOG_FILE

                    echo $(date -u)" Processing BROADCAST section by removing it if exists">> $PROCESS_LOG_FILE
                    OLD_VALUE=$(cat $CONFIG_FILE_PATH | grep BROADCAST)
                    NEW_VALUE=''
                    if [ ! -z $OLD_VALUE ];
                    then
                        sed -i -e "s|$OLD_VALUE|$NEW_VALUE|" $CONFIG_FILE_PATH
                    fi
                    cat $CONFIG_FILE_PATH>> $PROCESS_LOG_FILE

                    echo $(date -u)" Processing IPADDR section by removing it if exists">> $PROCESS_LOG_FILE
                    OLD_VALUE=$(cat $CONFIG_FILE_PATH | grep IPADDR)
                    NEW_VALUE=''
                    if [ ! -z $OLD_VALUE ];
                    then
                        sed -i -e "s|$OLD_VALUE|$NEW_VALUE|" $CONFIG_FILE_PATH
                    fi
                    cat $CONFIG_FILE_PATH>> $PROCESS_LOG_FILE

                    echo $(date -u)" Processing NETMASK section by removing it if exists">> $PROCESS_LOG_FILE
                    OLD_VALUE=$(cat $CONFIG_FILE_PATH | grep NETMASK)
                    NEW_VALUE=''
                    if [ ! -z $OLD_VALUE ];
                    then
                        sed -i -e "s|$OLD_VALUE|$NEW_VALUE|" $CONFIG_FILE_PATH
                    fi
                    cat $CONFIG_FILE_PATH>> $PROCESS_LOG_FILE

                    echo $(date -u)" Processing NETWORK section by removing it if exists">> $PROCESS_LOG_FILE
                    OLD_VALUE=$(cat $CONFIG_FILE_PATH | grep NETWORK)
                    NEW_VALUE=''
                    if [ ! -z $OLD_VALUE ];
                    then
                        sed -i -e "s|$OLD_VALUE|$NEW_VALUE|" $CONFIG_FILE_PATH
                    fi
                    cat $CONFIG_FILE_PATH>> $PROCESS_LOG_FILE

                    echo $(date -u)" Processing DNS1 section by removing it if exists">> $PROCESS_LOG_FILE
                    OLD_VALUE=$(cat $CONFIG_FILE_PATH | grep DNS1)
                    NEW_VALUE=''
                    if [ ! -z $OLD_VALUE ];
                    then
                        sed -i -e "s|$OLD_VALUE|$NEW_VALUE|" $CONFIG_FILE_PATH
                    fi
                    cat $CONFIG_FILE_PATH>> $PROCESS_LOG_FILE


                    echo $(date -u)" Processing DNS2 section by removing it if exists">> $PROCESS_LOG_FILE
                    OLD_VALUE=$(cat $CONFIG_FILE_PATH | grep DNS2)
                    NEW_VALUE=''
                    if [ ! -z $OLD_VALUE ];
                    then
                        sed -i -e "s|$OLD_VALUE|$NEW_VALUE|" $CONFIG_FILE_PATH
                    fi
                    cat $CONFIG_FILE_PATH>> $PROCESS_LOG_FILE

                    echo $(date -u)" Processing IPV4_FAILURE_FATAL section by removing it if exists">> $PROCESS_LOG_FILE
                    OLD_VALUE=$(cat $CONFIG_FILE_PATH | grep IPV4_FAILURE_FATAL)
                    NEW_VALUE=''
                    if [ ! -z $OLD_VALUE ];
                    then
                        sed -i -e "s|$OLD_VALUE|$NEW_VALUE|" $CONFIG_FILE_PATH
                    fi
                    cat $CONFIG_FILE_PATH>> $PROCESS_LOG_FILE

                    echo $(date -u)" Processing DEFROUTE section by removing it if exists">> $PROCESS_LOG_FILE
                    OLD_VALUE=$(cat $CONFIG_FILE_PATH | grep DEFROUTE)
                    NEW_VALUE=''
                    if [ ! -z $OLD_VALUE ];
                    then
                        sed -i -e "s|$OLD_VALUE|$NEW_VALUE|" $CONFIG_FILE_PATH
                    fi
                    cat $CONFIG_FILE_PATH>> $PROCESS_LOG_FILE

                    echo $(date -u)" Processing PREFIX section by removing it if exists">> $PROCESS_LOG_FILE
                    OLD_VALUE=$(cat $CONFIG_FILE_PATH | grep PREFIX)
                    NEW_VALUE=''
                    if [ ! -z $OLD_VALUE ];
                    then
                        sed -i -e "s|$OLD_VALUE|$NEW_VALUE|" $CONFIG_FILE_PATH
                    fi
                    cat $CONFIG_FILE_PATH>> $PROCESS_LOG_FILE

                    echo $(date -u)" Clean up empty lines">> $PROCESS_LOG_FILE
                    sed -i '/^$/d' $CONFIG_FILE_PATH

                    IS_NETWORK_RESTART_REQUIRED="True"
                else
                    echo $(date -u)" IP set to DHCP "$IS_STATIC_IP >> $PROCESS_LOG_FILE
                fi
            done
            if [ ! -z $IS_NETWORK_RESTART_REQUIRED ];
            then
                echo $(date -u)" Restarting network" >> $PROCESS_LOG_FILE
                service network restart
                rm -rf /etc/init.d/reiphandler
                echo $(date -u)" Preparing to reboot" >> $PROCESS_LOG_FILE
                reboot
            fi
            echo $(date -u)" Done" >> $PROCESS_LOG_FILE
            echo $(date -u)" Removing Lock File" >> $PROCESS_LOG_FILE
#        fi
    else
        echo $(date -u)" We're in VC. Suppressing all activity..." >> $PROCESS_LOG_FILE
    fi
    rm -rf ${LOCKFILE}
}

stop(){
# Remove our lock file
rm -rf ${LOCKFILE}
# Run that command that we wanted to run
echo $(date -u)" ReIP handler stopped" >> $PROCESS_LOG_FILE
}

case "$1" in
    start) start;;
    stop) stop;;
    *)
        echo $"Usage: $0 {start|stop}"
        exit 1
esac
exit 0
