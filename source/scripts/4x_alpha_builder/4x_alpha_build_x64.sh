#!/bin/bash
####################################################
#
# A silly little script to make installing a 
# Zenoss Core 4.x alpha development/testing machine
# to save me a little time next time a new release is cut
# VERY Centos 5 centric/dependant
#
#
###################################################

# Defaults for user provided input
latest_zenoss_build="4.1.70-1449"
default_arch="x86_64"

#Allow for overriding
if [ "$1" = "" ];then
	#use the default unless instructed otherwise
	zenoss_build=$latest_zenoss_build
else
	zenoss_build=$1	
fi

#Define where to get stuff based on arch
if [ "$2" = "" ];then
	#Use the default arch, unless told otherwise
	arch=$default_arch
else
	arch=$2
fi


# Where to get stuff. Base decisions on arch. Originally I was going to just
# use the arch variable, but its a little dicey in that file names don't always
# translate clearly. So just using if with a little duplication
if [ "$arch" = "x86_64" ];then
	jre_file="jre-6u31-linux-x64-rpm.bin"
	mysql_client_rpm="MySQL-client-5.5.20-1.linux2.6.x86_64.rpm"
	mysql_server_rpm="MySQL-server-5.5.20-1.linux2.6.x86_64.rpm"
	mysql_shared_rpm="MySQL-shared-5.5.20-1.linux2.6.x86_64.rpm"
	rpmforge_rpm_file="rpmforge-release-0.5.2-2.el5.rf.x86_64.rpm"
	
elif [ "$arch" = "i386" ]; then
	jre_file="jre-6u31-linux-i586-rpm.bin"
	mysql_client_rpm="MySQL-client-5.5.21-1.linux2.6.i386.rpm"
	mysql_server_rpm="MySQL-server-5.5.21-1.linux2.6.i386.rpm"
	mysql_shared_rpm="MySQL-shared-5.5.21-1.linux2.6.i386.rpm"
	rpmforge_rpm_file="rpmforge-release-0.5.2-2.el5.rf.i386.rpm"
else
	echo "Don't know where to get files for arch $arch"
	exit 1
fi

jre_download="http://download.oracle.com/otn-pub/java/jdk/6u31-b04/$jre_file"

zenoss_arch=$arch
zenoss_rpm_file="zenoss-$zenoss_build.el5.$zenoss_arch.rpm"
zenpack_rpm_file="zenoss-core-zenpacks-$zenoss_build.el5.$zenoss_arch.rpm"
zenoss_base_url="http://downloads.sourceforge.net/project/zenoss/zenoss-alpha/$zenoss_build"
zenoss_gpg_key="http://dev.zenoss.org/yum/RPM-GPG-KEY-zenoss"

rpm_forge_rpm_url="http://pkgs.repoforge.org/rpmforge-release/$rpmforge_rpm_file"


cd /tmp

echo "Downloading Files"
if [ ! -f $jre_file ];then
	echo "Downloading Oracle JRE"
	wget $jre_download
	chmod +x $jre_file
fi
if [ `rpm -qa | grep -c jre` -eq 0 ];then
	echo "Installating JRE"
	./$jre_file
fi
echo "Downloading Zenoss RPMs"
for file in $zenoss_rpm_file $zenpack_rpm_file;do
	if [ ! -f $file ];then
		wget $zenoss_base_url/$file
	fi
done


if [ `rpm -qa gpg-pubkey* | grep -c "aa5a1ad7-4829c08a"` -eq 0  ];then
	echo "Importing Zenoss GPG Key"
	rpm --import $zenoss_gpg_key
fi

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

echo "Installing Zenoss Dependency Repo"
rpm -ivh http://deps.zenoss.com/yum/zenossdeps.el5.noarch.rpm

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

#If your working with alpha, odds are you are going to need some zenpacks from source.
#lets install the git client
echo "Installing GIT client from RPMFORGE"
if [ `rpm -qa | grep -c -i git` -eq 0 ];then
	if [ `rpm -qa | grep -c -i rpmforge` -eq 0 ];then
		wget -N $rpm_forge_rpm_url
		rpm -ivh $rpmforge_rpm_file
	fi
	yum -y install git
fi

