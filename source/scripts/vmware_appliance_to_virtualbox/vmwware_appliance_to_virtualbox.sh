#!/bin/bash
###############################################
#
# Script to Download and Conver the the Zenoss
# Vmware appliance that Zenoss Inc. Provides
# and convert it to a virtual box VM
#
###############################################

# Some Default Variables
# @todo - Enhance this to take command line arguments for more flexibility
buildNumber="4.1.70-1474"
arch="x86_64"
baseFileName="zenoss-$buildNumber-$arch"
zipFileName="$baseFileName.vmware.zip"
zipFileDownloadUrl="http://downloads.sourceforge.net/project/zenoss/zenoss-alpha/$buildNumber/$zipFileName"

vmName="Zenoss_Appliance_$buildNumber"
homeDir=~
vmBasePath="$homeDir/VMs"


cd /tmp
if [ ! -f $zipFileName ]; then
	echo "Downloading $zipFileDownloadUrl"
	wget $zipFileDownloadUrl
else
	echo "Zip File was already downloading. Skipping download"
fi

# Create vm base path if it does not already exist
if [ ! -d $vmBasePath ]; then
	echo "creating $vmBasePath"
	mkdir $vmBasePath
fi

echo "Extracing VM Appliance"
echo $baseFileName/$baseFileName.vmdk
if [ ! -f $baseFileName/$baseFileName.vmdk ]; then
	unzip -o $zipFileName
else
	echo "Appears vmdk has already been extracted"
fi

#Create the VM if doesnt already exist
if [ ! -f $vmBasePath/$vmName/$baseFileName.vmdk ]; then
	echo "Creating New Virtual Machine named $vmName"
	VBoxManage createvm --name $vmName --basefolder $vmBasePath --register
	
	echo "Attempting to Locate Guest Additions ISO"
	isoLocation=`find / -iname "VBoxGuestAdditions.iso" -print -quit`
	echo "$isoLocation"
	
	if [ "$isoLocation" = "" ]; then
		echo "Unable to Find Guest Additions ISO"
		isoLocation="emptydrive"
	fi
	
	# Applying Customizations to VM
	VBoxManage modifyvm $vmName --ostype RedHat_64 --memory 2048 --nic1 nat --nictype1 82545EM --ioapic on
	VBoxManage storagectl $vmName --name "IDE Controller" --add ide --controller PIIX4
	VBoxManage storageattach $vmName --storagectl "IDE Controller" --type dvddrive --port 1 --device 0 --medium $isoLocation
	
	echo "Adding Port Forwards for SSH and Zope-HTTP"
	VBoxManage controlvm $vmName natpf1 "SSH,tcp,,8022,,22"
	VBoxManage controlvm $vmName natpf1 "ZOPE,tcp,,8080,,8080"
	
	echo "Copying Extracted VMDK and attaching it"
	cp $baseFileName/$baseFileName.vmdk $vmBasePath/$vmName/
	VBoxManage storagectl $vmName --name "SCSI Controller" --add scsi --controller LsiLogic
	VBoxManage storageattach $vmName --storagectl "SCSI Controller" --type hdd --port 0 --medium $vmBasePath/$vmName/$baseFileName.vmdk
else
	echo "VM Already Exists. Skipping Creation"
fi

echo "Starting the Virtual machine"
VBoxManage startvm $vmName


#Maybe some day I'll finish this part, and automate the tools
exit
read -p "Press an key once the VM has booted to the logon screen"

echo "Attempting to Logon"
#Sending one key at a time as it seems a common issues that sending all of them causes problems
#Send "root<enter>
for key in 13 18 18 14 1c; do VBoxManage controlvm $vmName keyboardputscancode $key && sleep 0.1; done
#Send Password "zenoss<enter>"
for key in 2c 12 31 18 1f 1f 1c; do VBoxManage controlvm $vmName keyboardputscancode $key && sleep 0.1; done
#Give logon a chance
sleep 5

#Send some scancodes to download and run the tool replacement script

