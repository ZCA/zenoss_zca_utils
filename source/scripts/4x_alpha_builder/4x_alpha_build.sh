#!/bin/bash
####################################################
#
# A silly little script to make installing a 
# Zenoss Core 4.x Beta development/testing machine
# to save me a little time next time a new release is cut
# VERY Centos/RHEL centric/dependant.
# Its assumed you are running this on a bare/clean machine
#
#
###################################################

try() {
	"$@"
	if [ $? -ne 0 ]; then
		echo "Command failure: $@"
		exit 1
	fi
}

# Defaults for user provided input
major="4.1.70"
build="1518"
latest_zenoss_build="$major-$build"
default_arch="x86_64"
# ftp mirror for MySQL to use for version auto-detection:
mysql_ftp_mirror="ftp://mirror.anl.gov/pub/mysql/Downloads/MySQL-5.5/"
#We have some very specific version requirements for RRDTool
rrdtool_ver="1.4.7"

cd /tmp

echo "Auto-detecting most recent MySQL Community release"
try rm -f .listing
try wget --no-remove-listing $mysql_ftp_mirror >/dev/null 2>&1
mysql_v=`cat .listing | awk '{ print $9 }' | grep MySQL-client | grep el6.x86_64.rpm | sort | tail -n 1`
# tweaks to isolate MySQL version:
mysql_v="${mysql_v##MySQL-client-}"
mysql_v="${mysql_v%%.el6.*}"
if [ "${mysql_v:0:1}" != "5" ]; then
	# sanity check
	mysql_v="5.5.24"
fi
rm -f .listing

echo "Attempting to Install Zenoss $latest_zenoss_build and components"

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
if [ `rpm -qa | egrep -c -i "^mysql-(libs|server)?"` -gt 0 ]; then
	if [ `rpm -qa | egrep -i "^mysql-(libs|server)?" | grep -c -v 5.5` -gt 0 ]; then
		echo "It appears you already have an older version of MySQL packages installed"
		echo "I'm too scared to continue. Please remove the following existing MySQL Packages:"
		rpm -qa | egrep -i "^mysql-(libs|server)?"
		exit 1
	else
		if [ `rpm -qa | egrep -c -i "mysql-server"` -gt 0 ];then
			echo "It appears MySQL 5.5 server is already installed. MySQL Installation  will be skipped"
			mysql_installed=1
		else
			echo "It appears you have some MySQL 5.5 packages, but not MySQL Server. I'll try to install"
		fi
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
	mysql_client_rpm="MySQL-client-$mysql_v.linux2.6.x86_64.rpm"
	mysql_server_rpm="MySQL-server-$mysql_v.linux2.6.x86_64.rpm"
	mysql_shared_rpm="MySQL-shared-$mysql_v.linux2.6.x86_64.rpm"
	rpmforge_rpm_file="rpmforge-release-0.5.2-2.$els.rf.x86_64.rpm"
	epel_rpm_file=epel-release-6-6.noarch.rpm
	epel_rpm_url=http://download.fedoraproject.org/pub/epel/6/i386/$epel_rpm_file
	
elif [ "$arch" = "i386" ]; then
	jre_file="jre-6u31-linux-i586-rpm.bin"
	jre_url="http://javadl.sun.com/webapps/download/AutoDL?BundleId=59620"
	mysql_client_rpm="MySQL-client-$mysql_v.linux2.6.i386.rpm"
	mysql_server_rpm="MySQL-server-$mysql_v.linux2.6.i386.rpm"
	mysql_shared_rpm="MySQL-shared-$mysql_v.linux2.6.i386.rpm"
	rpmforge_rpm_file="rpmforge-release-0.5.2-2.$els.rf.i386.rpm"
	epel_rpm_file=epel-release-5-4.noarch.rpm
	epel_rpm_url=http://dl.fedoraproject.org/pub/epel/5/i386/$epel_rpm_file
else
	echo "Don't know where to get files for arch $arch"
	exit 1
fi

echo "Enabling EPEL Repo"
if [ `rpm -qa | grep -c -i epel` -eq 0 ];then
	try wget -N $epel_rpm_url
	try rpm -ivh $epel_rpm_file
fi

echo "Enabling repoforge Repo"
if [ `rpm -qa | grep -c -i rpmforge` -eq 0 ];then
	try wget -N $rpmforge_rpm_file
	try rpm -ivh $rpmforge_rpm_file
fi

echo "Installing Required Packages"
try yum -y install libaio tk unixODBC erlang rabbitmq-server memcached perl-DBI net-snmp \
net-snmp-utils gmp libgomp libgcj.$arch libxslt dmidecode sysstat xorg-x11-fonts-Type1 ruby libdbi

#Some Package names are depend on el release
if [ "$elv" == "5" ]; then
	try yum -y install liberation-fonts
elif [ "$elv" == "6" ]; then
	try yum -y install liberation-fonts-common pkgconfig liberation-mono-fonts liberation-sans-fonts liberation-serif-fonts
fi

echo "Installing RRD Tools"
if [ `rpm -qa | grep -c -i rrdtool` -eq 0 ]; then
	rrdtool_loc="http://pkgs.repoforge.org/rrdtool"
	try wget $rrdtool_loc/rrdtool-$rrdtool_ver-1.el$elv.rfx.$arch.rpm
	try wget $rrdtool_loc/perl-rrdtool-$rrdtool_ver-1.el$elv.rfx.$arch.rpm
	try yum -y localinstall rrdtool-$rrdtool_ver-1.el$elv.rfx.$arch.rpm perl-rrdtool-$rrdtool_ver-1.el$elv.rfx.$arch.rpm
else
	echo "You already have rrdtool installed. Taking no action"
fi

if [ `rpm -qa | grep -c -i jre` -eq 0 ]; then
	if [ ! -f $jre_file ];then
		echo "Downloading Oracle JRE"
		try wget -N -O $jre_file $jre_url
		try chmod +x $jre_file
	fi
	if [ `rpm -qa | grep -c jre` -eq 0 ]; then
		echo "Installating JRE"
		try ./$jre_file
	fi
else
	echo "Appears you already have a JRE installed. I'm not going to install another one"
fi

echo "Downloading and installing MySQL RPMs"
if [ $mysql_installed -eq 0 ]; then
	#Only install if MySQL Is not already installed
	for file in $mysql_client_rpm $mysql_server_rpm $mysql_shared_rpm;
	do
		if [ ! -f $file ];then
			try wget -N http://dev.mysql.com/get/Downloads/MySQL-5.5/$file/from/http://mirror.services.wisc.edu/mysql/
		fi
		if [ ! -f $file ];then
			echo "Failed to download $file. I can't continue"
			exit 1
		fi
		rpm_entry=`echo $file | sed s/.x86_64.rpm//g | sed s/.i386.rpm//g | sed s/.i586.rpm//g`
		if [ `rpm -qa | grep -c $rpm_entry` -eq 0 ];then
			try rpm -ivh $file
		fi
	done
fi

zenoss_arch=$arch
zenoss_rpm_file="zenoss-$zenoss_build.$els.$zenoss_arch.rpm"
zenpack_rpm_file="zenoss-core-zenpacks-$zenoss_build.$els.$zenoss_arch.rpm"
zenoss_base_url="http://sourceforge.net/projects/zenoss/files/zenoss-beta/builds/$zenoss_build"
zenoss_gpg_key="http://dev.zenoss.org/yum/RPM-GPG-KEY-zenoss"
for file in $zenoss_rpm_file $zenpack_rpm_file;do
	if [ ! -f $file ];then
		echo "Downloading Zenoss RPMs"
		try wget -N $zenoss_base_url/$file
	fi
done

if [ `rpm -qa gpg-pubkey* | grep -c "aa5a1ad7-4829c08a"` -eq 0  ];then
	echo "Importing Zenoss GPG Key"
	try rpm --import $zenoss_gpg_key
fi

#echo "Installing Zenoss Dependency Repo"
#There is no EL6 rpm for this as of now. I'm not even entirelly sure we really need it if we have epel
#rpm -ivh http://deps.zenoss.com/yum/zenossdeps.el5.noarch.rpm

echo "Configuring and Starting some Base Services"
for service in rabbitmq-server memcached snmpd mysql; do
	try /sbin/chkconfig $service on
	try /sbin/service $service start
done

echo "Configuring MySQL"
try /sbin/service mysql restart
try /usr/bin/mysqladmin -u root password ''
try /usr/bin/mysqladmin -u root -h localhost password ''

echo "Installing Zenoss"
try rpm -ivh $zenoss_rpm_file

try /sbin/service zenoss start

echo "Installing Core ZenPacks"
try rpm -ivh $zenpack_rpm_file

echo "Please remember you can use the new zenpack --fetch command to install most zenpacks into your new core 4 Alpha install"


