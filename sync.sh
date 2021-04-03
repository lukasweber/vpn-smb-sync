#!/bin/bash

SMB_CREDENTIALS_FILE=/root/.smbcredentials
MOUNT_FOLDER=/mnt/share
TARGET_FOLDER=/app/target
: "${MAX_FILE_SIZE:=50m}"

mount_vpn_share() {
    echo "Connecting to VPN ..."
    echo $PASSWORD | openconnect -b -u $USERNAME --passwd-on-stdin $VPN_SERVER

    # we have to wait a few seconds until we try to mount the share
    sleep 3

    if [ ! -f "$SMB_CREDENTIALS_FILE" ]; then
        echo "username=$USERNAME" >> $SMB_CREDENTIALS_FILE
        echo "password=$PASSWORD" >> $SMB_CREDENTIALS_FILE
        echo "$SMB_CREDENTIALS_FILE was newly created because it didn't exist yet!"
    fi

    echo "Mounting share ..."
    mount -t cifs -o rw,vers=3.0,,iocharset=utf8,credentials=$SMB_CREDENTIALS_FILE $SMB_SHARE $MOUNT_FOLDER
}

sync_folders() {
    echo "Start syncing folders ..."
    for folder in $(echo $SMB_COPY_FOLDERS | sed "s/,/ /g")
    do
        mkdir -p $TARGET_FOLDER/$folder
        rsync -rvz --max-size=$MAX_FILE_SIZE $MOUNT_FOLDER/$folder/ $TARGET_FOLDER/$folder
        echo "Start copying folder $folder"
    done
    echo "Syncing folders sucessfully done!"
}

disconnect() {
    echo "Disconnecting from VPN ..."
    # unmount folder & disconnect from VPN
    umount $MOUNT_FOLDER
    kill -9 $(pidof openconnect)
}

check_vars() {
    var_names=("$@")
    for var_name in "${var_names[@]}"; do
        [ -z "${!var_name}" ] && echo "$var_name is unset." && var_unset=true
    done
    [ -n "$var_unset" ] && exit 1
    return 0
}

ask_password_ifnotset() {
    if [ -z ${PASSWORD+x} ]; then
        echo "Environment Variable PASSWORD is not set!"
        if [[ $- == *i* ]]; then
            echo "ERROR: Please set the environment variable 'PASSWORD' or run the container in interactive mode."
            exit 1
        fi
        stty -echo
        printf "Enter your Password: "
        read PASSWORD
        stty echo
    fi
}

check_vars USERNAME VPN_SERVER SMB_SHARE SMB_COPY_FOLDERS

# create folders within container
mkdir -p $TARGET_FOLDER
mkdir -p $MOUNT_FOLDER

ask_password_ifnotset
mount_vpn_share
sync_folders
disconnect
