#!/bin/bash
###############################################
#
# Once you have a converted VM, this script
# makes replacing the tools a little easier
#
###############################################

echo "Removing VMware Tools. Its normal to see some errors here"
vmware-uninstall-tools.pl

echo "Installing some Pre-Reqs"
yum -y install bzip2 make gcc

echo "Installing Guest Additions"
mkdir /media/ga
mount /dev/cdrom /media/ga
/media/ga/VBoxLinuxAdditions.run

echo "Rebooting"
reboot