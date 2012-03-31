=================================================
Fast Track an Alpha 4 Build on RHEL or Derivative
=================================================
:Author: David Petzel
:Date: 02/18/2012

.. contents::
   :depth: 4
   
Purpose
=======
In order to take some of the tedious process around building new
Zenoss Core Alpha 4 builds I put together a small shell script to handle
all the mundane tasks. Its nothing fancy, but should hopefully save you some
time in tracking down various downloads and such

The script is completly dependant on the fact that you are running it on 
a clean/fresh RHEL derivative. Its not going to work on another distro
like Ubuntu.

Requirements/Recommendations
============================
The following requirements must be met:
* You must be running on a RHEL derivative.
* Ensure you meet all other requirements as outlined in the official
  installation guide
* The machine you are running this on will need access to various internet
  sites.
* You should start with a minimal install to avoid any dependency issues
* You might want to disable iptables, or at least open up 8080 so you
  access the web ui after instalation is complete

Run It
======
Just run the following to get the ball rolling::
   
   wget -N https://raw.github.com/ZCA/zenoss_zca_utils/master/source/scripts/4x_alpha_builder/4x_alpha_build_$HOSTTYPE.sh
   sh 4x_alpha_build_$HOSTTYPE.sh
