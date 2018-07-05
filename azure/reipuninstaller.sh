#!/usr/bin/env bash

INSTALLATION_LOG=$1

echo 'Stopping service'>>$INSTALLATION_LOG
service reiphandler stop
echo 'Removing service source'>>$INSTALLATION_LOG
rm -rf /etc/reip/
echo 'Removing unit file'>>$INSTALLATION_LOG
rm -rf /etc/systemd/system/reiphandler.service
echo 'Removing service backup'>>$INSTALLATION_LOG
rm -rf reip_handler.sh
echo 'Removing service installer'>>$INSTALLATION_LOG
rm -rf installer.sh
echo 'Removing service service'>>$INSTALLATION_LOG
rm -rf /etc/init.d/reiphandler
echo 'Success'>>$INSTALLATION_LOG
