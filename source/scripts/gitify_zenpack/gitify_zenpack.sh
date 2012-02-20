#!/bin/bash
##########################################
#
# Take a ZenPack .egg file and 'gitify' it.
# The end result should be the ZenPack
# Source being saved to a new GitHub Repo
# under the ZCA Organization
#
#########################################


work_dir="/tmp"

if [ "$1"  == "" ]; then
  echo "You need supply the name of the ZenPack egg file"
  exit 1
else
  egg_file=$1
fi

echo "Going to gitify $egg_file"
declare -a name_parts=(`echo $egg_file | tr "-" "\n"`);
echo $name_parts
pack_name=${name_parts[0]}
pack_version=${name_parts[1]}

#Install the ZenPack
echo "Installing $pack_name version $pack_version"
zenpack --install=$work_dir/$egg_file

echo "Converting ZenPack to development mode"
cp $ZENHOME/Products/ZenModel/ZenPackTemplate/* $ZENHOME/ZenPacks/$egg_file


echo "Building Temp DMD script to finalize conversion"
dmd_file=$work_dir/write_setup.dmd
echo "import Globals" > $dmd_file
echo "from Products.ZenUtils.ZenScriptBase import ZenScriptBase" >> $dmd_file
echo "dmd = ZenScriptBase(connect=True).dmd" >> $dmd_file
echo "for pack in dmd.ZenPackManager.packs():" >> $dmd_file
echo "  if pack.id == \"$pack_name\":" >> $dmd_file
echo "    pack.writeSetupValues()" >> $dmd_file
echo "    exit()" >> $dmd_file

echo "Executing dmd script to finalize conversion"
python $dmd_file
 
echo "Relocating files outside of ZenPack Folder"
cp -r $ZENHOME/ZenPacks/$egg_file /$work_dir/$pack_name
zenpack --link --install=/$work_dir/$pack_name

echo "Initializing new local git repo"
cd $work_dir/$pack_name
git init

echo "Grabbing default .gitignore file from Zenoss"
wget https://raw.github.com/zenoss/Community-ZenPacks-SubModules/master/.gitignore

echo "Creating empty README.rst file. You should probably adding something to this file"
touch README.rst

echo "Commiting and Pushing to GITHUB"
git add .
git commit -a -m 'Initial Commit - Post EGG Extraction'
git remote add origin git@github.com:ZCA/$pack_name
github_user=`git config --global github.user`
github_key=`git config --global github.token`

#TODO Add some error checking here and prompt user for input if we couldnt fet github info
curl -k -F "login=$github_user" -F "token=$github_key" -i https://github.com/api/v2/json/repos/create -F "name=ZCA/$pack_name" -F "description=$pack_name"

git push -u origin master

echo "Done Pusing to GitHub. Cleaning Up"
zenpack --remove=$pack_name
cd /$work_dir
rm $dmd_file
rm -Rf $work_dir/$pack_name


