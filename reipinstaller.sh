#!/bin/sh
LOGS_FOLDER=/etc/reip/
INSTALLATION_LOG=/tmp/reip/installation.log
HANDLER_NAME='reiphandler.sh'
CONF_FILE_NAME='dhcp.conf'
REIP_HANDLER_PATH=$LOGS_FOLDER$HANDLER_NAME
CONF_FILE_PATH=$LOGS_FOLDER$CONF_FILE_NAME

chmod +x ./reipuninstaller.sh
./reipuninstaller.sh $INSTALLATION_LOG

mkdir $LOGS_FOLDER

echo $(date -u) "Copying handler file to it's permanent location">>$INSTALLATION_LOG
cp ./reiphandler.sh $REIP_HANDLER_PATH
cp ./dhcp.conf $CONF_FILE_PATH

echo $(date -u) "Generating service log file path">>$INSTALLATION_LOG
sed -i -e "s|-target-folder-|$LOGS_FOLDER|" $REIP_HANDLER_PATH

echo $(date -u) "Installing Handler">>$INSTALLATION_LOG
cp $REIP_HANDLER_PATH /etc/init.d/reiphandler

echo $(date -u) "Granting service execution permissions">>$INSTALLATION_LOG
chmod +x /etc/init.d/reiphandler

echo $(date -u) "Adding service to startup sequence">>$INSTALLATION_LOG
chkconfig --add reiphandler

echo $(date -u) "Adding handler to startup sequence">>$INSTALLATION_LOG
VERSION=$(rpm -q --queryformat '%{VERSION}' $(rpm -qa '(redhat|sl|slf|centos|oraclelinux)-release(|-server|-workstation|-client|-computenode)'))
echo $(date -u) "Resolved OS version is:"$VERSION>>$INSTALLATION_LOG
if  [[ $VERSION == 7.* ]] ;
    then
        echo $(date -u) "Copying .service unit file to target folder">>$INSTALLATION_LOG

        cp ./reiphandler.service /etc/systemd/system/

        echo $(date -u) "Adding service to startup sequence for RHEL 7.x">>$INSTALLATION_LOG
        systemctl enable reiphandler

        OLD_VALUE='#add_drivers+="'
        NEW_VALUE='add_drivers+="nvme xen-blkfront'
        IS_XEN_EXISTS=$(cat /etc/dracut.conf | grep 'nvme xen-blkfront')
        if [ ${#IS_XEN_EXISTS} -eq 0 ];
        then
            echo $(date -u)" Xen Definition not found. Adding xen drivers" >> $INSTALLATION_LOG
            sed -i -e "s|$OLD_VALUE|$NEW_VALUE|" /etc/dracut.conf
            dracut -f -v >> $INSTALLATION_LOG
        fi
    fi

#ln -s /etc/init.d/reiphandler /etc/rc.d/
echo $(date -u) "Starting service">>$INSTALLATION_LOG
service reiphandler start

