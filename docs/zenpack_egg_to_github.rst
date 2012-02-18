========================================================
Zenpack Egg to Github
========================================================
:Author: David Petzel
:Date: 02/18/2012

.. contents::
   :depth: 2

Purpose
======
There are times when someone might develop a ZenPack in the comfort of their own
environment and later wish to contribute it back to the community. In these case
the original author maybe unable, unwilling, or just not interested in making the
ZenPack source available on GitHub as is being recommended by Zenoss Inc.

There has been some discussions around allowing the ZCA to accept the standalone
egg file and will handle getting the ZenPack into GitHub. This document will 
outline the steps to take the egg and git into GitHub under the ZCA organization.

Its worth noting that you *do* need to do the conversion on a machine running
zenoss. I'd suggest you get the git client installed on your zenoss machine.
I personally think its easiest to also setup an SSH key pair under the zenoss
user on my zenoss development instance and link that key to my account


Assumptions
-----------
* Your running all these commands on your zenoss box
* You have configured your zenoss box to work with your GitHub account.
  This is a one time setup per box, regardless of how many packs you convert.
  If you have not already done this, see the section 
  `Setup Your Zenoss Box To interact With Your GitHub Account`_
* You are converting a fictional ZenPack named ZenPacks.community.gitify which
  was supplied to you as ZenPacks.community.gitify-1.0-py2.6.egg
* You have saved the egg file in your /tmp/ directory on your zenoss box

Setup Your Zenoss Box To interact With Your GitHub Account
----------------------------------------------------------
Ensure you have the git client installed on your Zenoss box. You'll also need to setup
an SSH key pair. I'd suggest setting up a key pair under your zenoss user login. GitHub
has a pretty good document that covers this so I won't re-invent the wheel.
http://help.github.com/linux-set-up-git/

I'd suggest you do make sure to setup GitHub token, as it will allow us to do everything in
conversion process from the command line on our Zenoss box, without having to drop out to
to the web UI to create the repo on GitHub when the time comes.

Do the Conversion
------
The first thing we need to do is install the egg::

  zenpack --install=ZenPacks.community.gitify-1.0-py2.6.egg

Now, following the steps outlined in the Developers Guide, switch the pack to development mode
and relocate it::

  cp $ZENHOME/Products/ZenModel/ZenPackTemplate/* $ZENHOME/ZenPacks/ZenPacks.community.gitify-1.0-py2.6.egg
  mkdir /tmp/ZenPacks.community.gitify
  cp -r $ZENHOME/ZenPacks/ZenPacks.community.gitify-1.0-py2.6.egg /tmp/ZenPacks.community.gitify
  zenpack --link --install=/tmp/ZenPacks.community.gitify

Now lets initialize a git repo. This will be a local git repo and in no way tied to GitHub yet::
  
  cd /tmp/ZenPacks.community.gitify
  git init

You should see something that looks like::
  
  Initialized empty Git repository in /tmp/ZenPacks.community.gitify/.git/

Now that we have an empty git repo, lets setup a few default files. Of note, we are going to pull down
a standard .gitignore file supplied by Zenoss, as well as creating our base README.rst file which GitHub
wants and will also serve as the file in which we will document the ZenPack::

  wget https://raw.github.com/zenoss/Community-ZenPacks-SubModules/master/.gitignore
  touch README.rst

Now we commit all the stuff we just did (This still won't result in interactions with GitHub)::

  git add .
  git commit -a -m 'Initial Commit - Post EGG Extraction'

Make your local git repo aware of the version on GitHub (no actualy interaction occurs yet)::
  
  git remote add origin git@github.com:ZCA/ZenPacks.community.gitify

Now we actually create the repo on GitHub. You can do this in the Web UI or using the API::

  curl -k -F 'login=YourUserName' -F 'token=YourAPIToken' -i https://github.com/api/v2/json/repos/create -F 'name=ZenPacks.community.gitify' -F 'description=Fill in a description for this ZenPack'
  
You will know this works based on the response. You'll see some JSON indicating success. Now its time to push everything up to GitHub::

  git push -u origin master

That should just above cover it. You can test by checking out the new git repo into a seperate directory
and doing a development install::

  mkdir /tmp/install_test
  cd /tmp/install_test
  git clone git://github.com/ZCA/ZenPacks.community.gitify.git
  zenpack --link --install=ZenPacks.community.gitify
  
