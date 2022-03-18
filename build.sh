#!/bin/sh

#build file tree
if [ ! -e bin ]
then
  mkdir bin
fi

if [ ! -e conf ]
then
  mkdir conf
fi

if [ ! -e data ]
then
  mkdir data
fi

if [ ! -e src ]
then
  mkdir src
fi

if [ ! -e test ]
then
  mkdir test
fi

if [ ! -e var ]
then
  mkdir var
fi

#clone sources
cd data
#git clone https://github.com/twohoursonelife/OneLifeData7.git .
git clone https://github.com/olivier-zami/OneLifeData7.git .
git pull --tags
rm */cache.fcz
rm */bin_*cache.fcz
cd ..

cd src
#git clone https://github.com/twohoursonelife/OneLife.git .
git clone --recursive --branch refacto https://github.com/olivier-zami/OneLife.git .
git pull --tags

#clone minorGems and other third party library
#if [ ! -e third_party ]
#then
#  mkdir third_party
#fi

#cd third_party
#if [ ! -e minorGems ]
#then
#  git submodule add https://github.com/twohoursonelife/minorGems.git
#  cd minorGems
#  git pull --tags
#  cd ..
#fi
#cd .. #third_party
#cd .. #src

#
cd src
#./configure 1
export MG_PATH="third_party/minorGems"
export TARGET_MAKEFILE_PATH="gameSource"
# pass all arguments into main configure
third_party/minorGems/game/platforms/SDL/configure 1

#make client + editor
cd gameSource
make
echo 1 > settings/useCustomServer.ini

sh ./makeEditor.sh

ln -s ../../data/animations .
ln -s ../../data/categories .
ln -s ../../data/ground .
ln -s ../../data/music .
ln -s ../../data/objects .
ln -s ../../data/overlays .
ln -s ../../data/scenes .
ln -s ../../data/sounds .
ln -s ../../data/sprites .
ln -s ../../data/transitions .
ln -s ../../data/dataVersionNumber.txt .

#make server
cd ../server
#./configure 1
export MG_PATH="../third_party/minorGems"
export TARGET_MAKEFILE_PATH="."

# pass all arguments into main configure
#../third_party/minorGems/game/platforms/SDL/configure 1
MG_PATH_DEFINED=`printenv | grep -c '^MG_PATH='`


TARGET_MAKEFILE_PATH_DEFINED=`printenv | grep -c '^TARGET_MAKEFILE_PATH='`


if [ "$MG_PATH_DEFINED" = "1" ]
then
	mgPath="$MG_PATH"
else
	mgPath="../minorGems"
fi


if [ "$TARGET_MAKEFILE_PATH_DEFINED" = "1" ]
then
	targetPath="$TARGET_MAKEFILE_PATH"
else
	targetPath="gameSource"
fi


targetMakefile="$targetPath/Makefile"


if [ "$#" -gt "0" ] ; then
  if [ "$1" -lt "4" ] ; then
    if [ "$1" -gt "0" ] ; then
      platformSelection="$1"
    fi
  fi
fi



if [ "$#" -gt "1" ] ; then
  mgPath="$2";
fi




while [ -z "$platformSelection" ]
do
  echo "select platform:"

  echo "  1 --  GNU/Linux"
  echo "  2 --  MacOSX"
  echo "  3 --  Win32 using MinGW"
  echo "  4 --  Raspbian on Raspberry Pi (experimental)"
  echo "  q --  quit"

  echo ""
  echo -n "> "

  read platformSelection

	if [ "$platformSelection" = "q" ]
  then
    exit 1
  fi

    # use ASCII comparison.
	if [ "$platformSelection" -gt "4" ]
    then
        platformSelection=""
  fi
    if [ "$platformSelection" -lt "1" ]
    then
        platformSelection=""
    fi
done

# use partial makefiles from minorGems project
makefileMinorGems="$mgPath/build/Makefile.minorGems"
makefileMinorGemsTargets="$mgPath/build/Makefile.minorGems_targets"
platformName="Generic"
platformMakefile="generic"
makefilePath="$mgPath/game/platforms/SDL"
commonMakefile="$makefilePath/Makefile.common"
makefileAll="$makefilePath/Makefile.all"

case "$platformSelection" in
    "1" )
        platformName="GNU/Linux"
        platformMakefile="$makefilePath/Makefile.GnuLinux"
    ;;
    "2" )
        platformName="MacOSX"
        platformMakefile="$makefilePath/Makefile.MacOSX"
    ;;
    "3" )
        platformName="Win32 MinGW"
        platformMakefile="$makefilePath/Makefile.MinGW"
    ;;
    "4" )
        platformName="Raspbian"
        platformMakefile="$makefilePath/Makefile.Raspbian"
    ;;
esac

rm -f Makefile.temp
echo "# Auto-generated by game9/configure for the $platformName platform.  Do not edit manually." > Makefile.temp

rm -f $targetMakefile
cat Makefile.temp $platformMakefile $commonMakefile $makefileMinorGems $makefileAll $makefileMinorGemsTargets > $targetMakefile

rm Makefile.temp

make

ln -s ../../data/categories .
ln -s ../../data/objects .
ln -s ../../data/transitions .
ln -s ../../data/tutorialMaps .
ln -s ../../data/dataVersionNumber.txt .


git for-each-ref --sort=-creatordate --format '%(refname:short)' --count=1 refs/tags/OneLife_v* | sed -e 's/OneLife_v//' > serverCodeVersionNumber.txt


echo 0 > settings/requireTicketServerCheck.ini
echo 1 > settings/forceEveLocation.ini
