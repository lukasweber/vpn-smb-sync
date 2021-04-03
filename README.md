# vpn-smb-sync

## :question: Problem

Do you know that situation of being at a university and your profs use an oldschool SMB share in the university network to handout teaching material? 

The manual process of connecting, mounting and getting the latest files takes quite a while everytime something has been updated.

## :bulb: Solution

This simple script tries to solve this problem by doing all of the following work for you ;)

* :white_check_mark: **Connects to the VPN in an isolated docker container** (using [openconnect](http://www.infradead.org/openconnect/)) (so the rest of your computer will be still connected to the current network)
* :white_check_mark: **Mounts the SMB share into your container** (using [cifs](https://wiki.samba.org/index.php/LinuxCIFS_utils))
* :white_check_mark: **Syncs desired folders to a docker volume respectively a local folder** (using [rsync](https://linux.die.net/man/1/rsync))

## Usage

### Build

```bash
docker build -t vpn-smb-sync .
```

### Examples

**IMPORTANT: Please note that we have to provide quite strong kernel capabilities to the container, so it's not recommended to use it for any other purpose than personal usage!**

**Run the container in interactive mode (by typing the password manually) and sync the folders `folder1,folder2/childfolder` to `/home/user/sync`:**

```bash
docker run -it --rm --cap-add NET_ADMIN --cap-add SYS_ADMIN --cap-add DAC_READ_SEARCH \
    -v /home/user/sync:/app/target \
    -e VPN_SERVER=vpn.server.com \
    -e USERNAME=myusername \
    -e SMB_SHARE=//smb.server.com/share \
    -e SMB_COPY_FOLDERS=folder1,folder2/childfolder \
    vpn-smb-sync
```

**Run the same above without any interaction:**

```bash
docker run --rm --cap-add NET_ADMIN --cap-add SYS_ADMIN --cap-add DAC_READ_SEARCH \
    -v /home/user/sync:/app/target \
    -e VPN_SERVER=vpn.server.com \
    -e USERNAME=myusername \
    -e PASSWORD=mypassword \
    -e SMB_SHARE=//smb.server.com/share \
    -e SMB_COPY_FOLDERS=folder1,folder2/childfolder \
    vpn-smb-sync
```

### Environment Variables

* `VPN_SERVER` (required): Hostname of the VPN server which shall be used to connect using openconnect
* `SMB_SHARE` (required): Address of the SMB share which shall be mounted within the container. Typically this address is something like `//my-share.com/share`.
* `SMB_COPY_FOLDERS` (required): Comma-separated list of child folders shall be **recursively** copied.
* `USERNAME` (required): Username which is used for the VPN- **and** SMB-Login.
* `PASSWORD` (optional): Password which is used for the VPN- **and** SMB-Login. *If you don't want to provide it directly, you can also run the container in interactive mode (using `-it`) and type it manually.*
* `MAX_FILE_SIZE` (optional, default: `50m`): Max file size used during the copy process according to `rsync --max-size=SIZE` 
