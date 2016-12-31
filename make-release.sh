#!/bin/bash

## This script will compile Gluon for all architectures, create the
## manifest and sign it. For that, you must have clone gluon and have a
## valid site config. Additionally, the signing key must be present in
## ../../ecdsa-key-secret or defined as first argument.
## The second argument defines the branch (stable, beta, experimental).
## The third argument defines the version.
## Call from site directory with the version and branch variables
## properly configured in this script.

# if version is unset, will use the default experimental version from site.mk
VERSION=${3:-"2016.2.2~rc$(date '+%y%m%d%H%M')"}
# branch must be set to either experimental, beta or stable
BRANCH=${2:-"stable"}
# must point to valid ecdsa signing key created by ecdsakeygen, relative to Gluon base directory
SIGNING_KEY=${1:-"../ecdsa-key-secret"}
#BROKEN must be set to "" or "BROKEN=1"
BROKEN="BROKEN=1"
# Cores of your computer +1
NUM_CORES_PLUS_ONE="2"

cd ../
if [ ! -d "site" ]; then
	echo "This script must be called from within the site directory"
	exit
fi

if [ "$(whoami)" == "root" ]; then
	echo "Make may not be run as root"
	return
fi

echo "############## starting build process #################" >> build.log
date >> build.log
echo "if you want to start over empty the folder ../output/"
echo "see debug output with"
echo "tail -f ../build.log &"
sleep 3

#rm -r output
ONLY_11S="ramips-rt305x ramips-mt7621"
BANANAPI="sunxi"
RASPBPI="brcm2708-bcm2708 brcm2708-bcm2709"
X86="x86-64 x86-generic x86-kvm_guest x86-xen_domu"
WDR4900="mpc85xx-generic"
for TARGET in ar71xx-generic $ONLY_11S ar71xx-mikrotik ar71xx-nand $WDR4900 $RASPBPI $BANANAPI $X86 
do
	date >> build.log
	if [ -z "$VERSION" ]
	then
		echo "Starting work on target $TARGET" | tee -a build.log
		echo -e "\n\n\nmake -j$NUM_CORES_PLUS_ONE -Orecurse GLUON_TARGET=$TARGET GLUON_BRANCH=stable update" >> build.log
		make clean
		make -j$NUM_CORES_PLUS_ONE -Orecurse GLUON_TARGET=$TARGET GLUON_BRANCH=stable update >> build.log 2>&1
		echo -e "\n\n\nmake -j$NUM_CORES_PLUS_ONE -Orecurse GLUON_TARGET=$TARGET GLUON_BRANCH=stable clean" >> build.log
		make -j$NUM_CORES_PLUS_ONE -Orecurse GLUON_TARGET=$TARGET GLUON_BRANCH=stable clean >> build.log 2>&1
		echo -e "\n\n\nmake -j$NUM_CORES_PLUS_ONE -Orecurse GLUON_TARGET=$TARGET GLUON_BRANCH=stable V=s $BROKEN" >> build.log
		make -j$NUM_CORES_PLUS_ONE -Orecurse GLUON_TARGET=$TARGET GLUON_BRANCH=stable V=s $BROKEN >> build.log 2>&1
		echo -e "\n\n\n============================================================\n\n" >> build.log
		make clean
	else
		echo "Starting work on target $TARGET" | tee -a build.log
		echo -e "\n\n\nmake -j$NUM_CORES_PLUS_ONE -Orecurse GLUON_TARGET=$TARGET GLUON_BRANCH=stable GLUON_RELEASE=$VERSION update" >> build.log
		make -j$NUM_CORES_PLUS_ONE -Orecurse GLUON_TARGET=$TARGET GLUON_BRANCH=stable GLUON_RELEASE=$VERSION update >> build.log 2>&1
		echo -e "\n\n\nmake -j$NUM_CORES_PLUS_ONE -Orecurse GLUON_TARGET=$TARGET GLUON_BRANCH=stable GLUON_RELEASE=$VERSION clean" >> build.log
		make -j$NUM_CORES_PLUS_ONE -Orecurse GLUON_TARGET=$TARGET GLUON_BRANCH=stable GLUON_RELEASE=$VERSION clean >> build.log 2>&1
		echo -e "\n\n\nmake -j$NUM_CORES_PLUS_ONE -Orecurse GLUON_TARGET=$TARGET GLUON_BRANCH=stable GLUON_RELEASE=$VERSION V=s $BROKEN" >> build.log
		make -j$NUM_CORES_PLUS_ONE -Orecurse GLUON_TARGET=$TARGET GLUON_BRANCH=stable GLUON_RELEASE=$VERSION V=s $BROKEN >> build.log 2>&1
		echo -e "\n\n\n============================================================\n\n" >> build.log
		make clean
	fi
done
date >> build.log

echo "Compilation complete, creating manifest(s)" | tee -a build.log

echo -e "make -j$NUM_CORES_PLUS_ONE -Orecurse GLUON_BRANCH=experimental manifest" >> build.log
make -j$NUM_CORES_PLUS_ONE -Orecurse GLUON_BRANCH=experimental manifest >> build.log 2>&1
echo -e "\n\n\n============================================================\n\n" >> build.log

if [[ "$BRANCH" == "beta" ]] || [[ "$BRANCH" == "stable" ]]
then
	echo -e "make -j$NUM_CORES_PLUS_ONE -Orecurse GLUON_BRANCH=beta manifest" >> build.log
	make -j$NUM_CORES_PLUS_ONE -Orecurse GLUON_BRANCH=beta manifest >> build.log 2>&1
	echo -e "\n\n\n============================================================\n\n" >> build.log
fi

if [[ "$BRANCH" == "stable" ]]
then
	echo -e "make -j$NUM_CORES_PLUS_ONE -Orecurse GLUON_BRANCH=stable manifest" >> build.log
	make -j$NUM_CORES_PLUS_ONE -Orecurse GLUON_BRANCH=stable manifest >> build.log 2>&1
	echo -e "\n\n\n============================================================\n\n" >> build.log
fi

make clean
echo "Manifest creation complete, signing manifest"

echo -e "contrib/sign.sh $SIGNING_KEY output/images/sysupgrade/experimental.manifest" >> build.log
contrib/sign.sh $SIGNING_KEY output/images/sysupgrade/experimental.manifest >> build.log 2>&1

if [[ "$BRANCH" == "beta" ]] || [[ "$BRANCH" == "stable" ]]
then
	echo -e "contrib/sign.sh $SIGNING_KEY output/images/sysupgrade/beta.manifest" >> build.log
	contrib/sign.sh $SIGNING_KEY output/images/sysupgrade/beta.manifest >> build.log 2>&1
fi

if [[ "$BRANCH" == "stable" ]]
then
	echo -e "contrib/sign.sh $SIGNING_KEY output/images/sysupgrade/stable.manifest" >> build.log
	contrib/sign.sh $SIGNING_KEY output/images/sysupgrade/stable.manifest >> build.log 2>&1
fi
cd site
date >> ../build.log
mv -v ../output/images "../output/$VERSION"
echo "Done :)"
