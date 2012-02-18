========================================================
Converting Zenoss VMWare Virtual Appliance to VirtualBox
========================================================
"Author": David Petzel
"Date": 02/18/2012

.. contents::
   :depth: 4
   
Purpose
=======
So you can use the VMWare Appliance Zenoss Inc. provides under
VirtualBox

Instructions
============

Linux
-----

Scripted
********
If you want to save your save some copy/paste time a script is available 
that should automatically handle most of the steps below. 
The following short set of commands shoulds get you up an running. 
If you have an issues with the script, you should be able to fall back 
on the manual steps, or maybe even fix the script and let me know the changes 
so I can incorporate them::
  
  cd /tmp
  wget http://raw.github.com/ZCA/zenoss_zca_utils/master/source/scripts/vmware_appliance_to_virtualbox/vmwware_appliance_to_virtualbox.sh
  chmod +x vmwware_appliance_to_virtualbox.sh
  ./vmwware_appliance_to_virtualbox.sh

At this point the VM should be converted and booting up. Once it has finished booting, login to the console and run the following commands *from within* the virtual machine::

  cd /tmp
  wget http://raw.github.com/ZCA/zenoss_zca_utils/master/source/scripts/vmware_appliance_to_virtualbox/replace_tools_with_additions.sh
  chmod +x replace_tools_with_additions.sh
  ./replace_tools_with_additions.sh

Manual
******

* Download the existing VMware Image::

   cd /tmp
   wget http://downloads.sourceforge.net/project/zenoss/zenoss-alpha/4.1.70-1427/zenoss-4.1.70-1427-x86_64.vmware.zip
   
* Unzip the downloaded zip file::

   unzip zenoss-4.1.70-1427-x86_64.vmware.zip
   
* Create a new VirtualBox VM::

   VM_NAME="Zenoss_4.1_Appliance"
   VM_BASE_PATH=/VMs
   sudo mkdir $VM_BASE_PATH
   sudo chmod 777 $VM_BASE_PATH
   VBoxManage createvm --name $VM_NAME --basefolder $VM_BASE_PATH --register
   
* Move the VMDK file over to the VM's directory::

   mv zenoss-4.1.70-1427-x86_64.vmdk $VM_BASE_PATH/$VM_NAME/
   
* Change Settings on the newly created VM::

   VBoxManage modifyvm $VM_NAME --ostype RedHat_64 --memory 2048 --nic1 nat --nictype1 82545EM --ioapic on

* Attach the VMDK file to the VM::

   VBoxManage storagectl $VM_NAME --name "SCSI Controller" --add scsi --controller LsiLogic
   VBoxManage storageattach $VM_NAME --storagectl "SCSI Controller" --type hdd --port 0 --medium $VM_BASE_PATH/$VM_NAME/zenoss-4.1.70-1427-x86_64.vmdk
   
* Add a DVD/CD Drive (At a minimum you'll need this for installing Guest Additions)::

   VBoxManage storagectl $VM_NAME --name "IDE Controller" --add ide --controller PIIX4
   VBoxManage storageattach $VM_NAME --storagectl "IDE Controller" --type dvddrive --port 1 --device 0 --medium emptydrive
   
* Power on the new Virtual Machine::

   VBoxManage startvm $VM_NAME

* Once the VM has started up, log into the console and Remove VMWare Tools::

   vmware-uninstall-tools.pl

* Use the VirtualBox documentation to install VirtualBox Guest Additions


Windows
-------

Scripted
********
Maybe some day

Manual
******

Lets get our powershell on...All commands are run in a power shell prompt

* Setup some Variables::

   $buildNumber = "4.1.70-1434" 
   $arch = "x86_64"  
   $baseFileName = "zenoss-$buildNumber-$arch"
   $zipFileName = "$baseFileName.vmware.zip"
   $zipFileDownloadUrl = "http://downloads.sourceforge.net/project/zenoss/zenoss-alpha/$buildNumber/$zipFileName"
   
   $VM_NAME="Zenoss_Appliance_$buildNumber"
   $VM_BASE_PATH="\VMs"

* Download the existing VMware Image::

   cd \temp
   $webclient = New-Object System.Net.WebClient
   echo "Going to Download File. This will take a long time without output. Be Patient"
   $webclient.DownloadFile($zipFileDownloadUrl,"$pwd\$zipFileName")
   
* Unzip the downloaded zip file::

   $shell_app=new-object -com shell.application
   $zip_file = $shell_app.namespace((Get-Location).Path + "\$zipFileName")
   $destination = $shell_app.namespace((Get-Location).Path)
   $destination.Copyhere($zip_file.items())
   
* Create a new VirtualBox VM::

   if ((Test-Path -path $VM_BASE_PATH) -ne $True){New-Item $VM_BASE_PATH -type directory}
   VBoxManage createvm --name $VM_NAME --basefolder $VM_BASE_PATH --register
   
* Move the VMDK file over to the VM's directory::

   mv $baseFileName\$baseFileName.vmdk $VM_BASE_PATH\$VM_NAME\
   
* Change Settings on the newly created VM::

   VBoxManage modifyvm $VM_NAME --ostype RedHat_64 --memory 2048 --nic1 nat --nictype1 82545EM --ioapic on

* Attach the VMDK file to the VM::

   VBoxManage storagectl $VM_NAME --name "SCSI Controller" --add scsi --controller LsiLogic
   VBoxManage storageattach $VM_NAME --storagectl "SCSI Controller" --type hdd --port 0 --medium $VM_BASE_PATH\$VM_NAME\$baseFileName.vmdk
   
* Add a DVD/CD Drive (At a minimum you'll need this for installing Guest Additions)::

   VBoxManage storagectl $VM_NAME --name "IDE Controller" --add ide --controller PIIX4
   VBoxManage storageattach $VM_NAME --storagectl "IDE Controller" --type dvddrive --port 1 --device 0 --medium (get-command VBoxGuestAdditions.iso).Path

* Some Optional Port forwards I find useful::
   
   VBoxManage controlvm $VM_NAME natpf1 "SSH,tcp,,8022,,22"
   VBoxManage controlvm $VM_NAME natpf1 "ZOPE,tcp,,8080,,8080"

* Power on the new Virtual Machine::

   VBoxManage startvm $VM_NAME

* Once the VM has started up, log into the console (root/zenoss) and Remove VMWare Tools::

   vmware-uninstall-tools.pl
   
* While still logged into the console, install VirtualBox guest additions::

   yum -y install bzip2 make gcc
   mkdir /media/ga
   mount /dev/cdrom /media/ga
   /media/ga/VBoxLinuxAdditions.run
      
* Reboot for good measure::

   reboot
