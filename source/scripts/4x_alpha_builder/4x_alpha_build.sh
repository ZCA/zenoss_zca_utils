#!/bin/bash
####################################################
#
# A silly little script to make installing a 
# Zenoss Core 4.x alpha development/testing machine
# to save me a little time next time a new release is cut
# VERY Centos 5 centric/dependant.
# Its assumed you are running this on a bare/clean machine
#
#
###################################################

# Defaults for user provided input
major="4.1.70"
build="1469"
latest_zenoss_build="$major-$build"
default_arch="x86_64"

#Define where to get stuff based on arch
if [ "$1" = "" ];then
	#Use the default arch, unless told otherwise
	arch=$default_arch
else
	arch=$1
fi

#Allow for overriding
if [ "$2" = "" ];then
	#use the default unless instructed otherwise
	zenoss_build=$latest_zenoss_build
else
	zenoss_build=$2
fi



echo "Ensuring This server is in a clean state before we start"
mysql_installed=0
if [ `rpm -qa | grep -c -i mysql` -gt 0 ]; then
	if [ `rpm -qa | grep -i mysql | grep -c -v 5.5` -gt 0 ]; then
		echo "It appears you already have an older version of MySQL Install"
		echo "I'm to scared to continue. Please remove existing MySQL Packages"
		exit 1
	else
		echo "It appears MySQL 5.5 is already installed. MySQL Installation  will be skipped"
		mysql_installed=1
	fi
fi

echo "Ensuring Zenoss RPMs are not already present"
if [ `rpm -qa | grep -c -i zenoss` -gt 0 ]; then
	echo "I see Zenoss Packages already installed. I can't handle that"
	exit 1
fi

#Now that RHEL6 RPMs are released, lets try to be smart and pick RPMs based on that
if [ -f /etc/redhat-release ]; then
	elv=`cat /etc/redhat-release | gawk 'BEGIN {FS="release "} {print $2}' | gawk 'BEGIN {FS="."} {print $1}'`
	#EnterpriseLinux Version String. Just a shortcut to be used later
	els=el$elv
else
	#Bail
	echo "Unable to determine version. I can't continue"
	exit 1
fi


# Where to get stuff. Base decisions on arch. Originally I was going to just
# use the arch variable, but its a little dicey in that file names don't always
# translate clearly. So just using if with a little duplication
if [ "$arch" = "x86_64" ]; then
	jre_file="jre-6u31-linux-x64-rpm.bin"
	jre_url="http://javadl.sun.com/webapps/download/AutoDL?BundleId=59622"
	mysql_client_rpm="MySQL-client-5.5.21-1.linux2.6.x86_64.rpm"
	mysql_server_rpm="MySQL-server-5.5.21-1.linux2.6.x86_64.rpm"
	mysql_shared_rpm="MySQL-shared-5.5.21-1.linux2.6.x86_64.rpm"
	rpmforge_rpm_file="rpmforge-release-0.5.2-2.$els.rf.x86_64.rpm"
	
elif [ "$arch" = "i386" ]; then
	jre_file="jre-6u31-linux-i586-rpm.bin"
	jre_url="http://javadl.sun.com/webapps/download/AutoDL?BundleId=59620"
	mysql_client_rpm="MySQL-client-5.5.21-1.linux2.6.i386.rpm"
	mysql_server_rpm="MySQL-server-5.5.21-1.linux2.6.i386.rpm"
	mysql_shared_rpm="MySQL-shared-5.5.21-1.linux2.6.i386.rpm"
	rpmforge_rpm_file="rpmforge-release-0.5.2-2.$els.rf.i386.rpm"
else
	echo "Don't know where to get files for arch $arch"
	exit 1
fi

rpm_forge_rpm_url="http://pkgs.repoforge.org/rpmforge-release/$rpmforge_rpm_file"


cd /tmp

echo "Downloading Files"
if [ `rpm -qa | grep -c -i jre` -eq 0 ]; then
	if [ ! -f $jre_file ];then
		echo "Downloading Oracle JRE"
		wget -O $jre_file $jre_url
		chmod +x $jre_file
	fi
	if [ `rpm -qa | grep -c jre` -eq 0 ]; then
		echo "Installating JRE"
		./$jre_file
	fi
else
	echo "Appears you already have a JRE installed. I'm not going to install another one"
fi

echo "Downloading Zenoss RPMs"
zenoss_arch=$arch
zenoss_rpm_file="zenoss-$zenoss_build.$els.$zenoss_arch.rpm"
zenpack_rpm_file="zenoss-core-zenpacks-$zenoss_build.$els.$zenoss_arch.rpm"
zenoss_base_url="http://downloads.sourceforge.net/project/zenoss/zenoss-alpha/$zenoss_build"
zenoss_gpg_key="http://dev.zenoss.org/yum/RPM-GPG-KEY-zenoss"
for file in $zenoss_rpm_file $zenpack_rpm_file;do
	if [ ! -f $file ];then
		wget $zenoss_base_url/$file
	fi
done


if [ `rpm -qa gpg-pubkey* | grep -c "aa5a1ad7-4829c08a"` -eq 0  ];then
	echo "Importing Zenoss GPG Key"
	rpm --import $zenoss_gpg_key
fi

if [ $mysql_installed -eq 0 ]; then
	#Only install if MySQL Is not already installed
	for file in $mysql_client_rpm $mysql_server_rpm $mysql_shared_rpm;
	do
		if [ ! -f $file ];then
			wget http://dev.mysql.com/get/Downloads/MySQL-5.5/$file/from/http://mirror.services.wisc.edu/mysql/
		fi
		rpm_entry=`echo $file | sed s/.x86_64.rpm//g | sed s/.i386.rpm//g | sed s/.i586.rpm//g`
		if [ `rpm -qa | grep -c $rpm_entry` -eq 0 ];then
			rpm -ivh $file
		fi
	done
fi

echo "Installing Zenoss Dependency Repo"
rpm -ivh http://deps.zenoss.com/yum/zenossdeps.$els.noarch.rpm

echo "Installing Required Packages"
yum -y install tk unixODBC erlang rabbitmq-server memcached perl-DBI net-snmp \
net-snmp-utils gmp libgomp libgcj.$arch libxslt liberation-fonts

echo "Configuring and Starting some Base Services"
for service in rabbitmq-server memcached snmpd mysql; do
	/sbin/chkconfig $service on
	/sbin/service $service start
done

echo "Configuring MySQL"
/sbin/service mysql restart
/usr/bin/mysqladmin -u root password ''
/usr/bin/mysqladmin -u root -h localhost password ''

echo "Installing Zenoss"
rpm -ivh $zenoss_rpm_file

/sbin/service zenoss start

echo "Installing Core ZenPacks"
rpm -ivh $zenpack_rpm_file


echo "Please remember you can use the new zenpack --fetch command to install most zenpacks into your new core 4 Alpha install"
#If your working with alpha, odds are you are going to need some zenpacks from source.
#lets install the git client
#echo "Installing GIT client from RPMFORGE"
#if [ `rpm -qa | grep -c -i git` -eq 0 ];then
#	if [ `rpm -qa | grep -c -i rpmforge` -eq 0 ];then
#		wget -N $rpm_forge_rpm_url
#		rpm -ivh $rpmforge_rpm_file
#	fi
#	yum -y install git
#fi

