Gluon versions used for specific FreeMesh Ireland Firmware builds:

* 0.1: v2016.2.2 + Eulenfunk patch - B.A.T.M.A.N. IV (compat 15) + 802.11s only

Documentation: https://gluon.readthedocs.org/en/v2016.2/user/site.html

Build
-----
You can easily create your own experimental build with these commands:

    sudo apt-get install git make gcc g++ unzip libncurses5-dev zlib1g-dev subversion gawk bzip2 libssl-dev
    git clone https://github.com/freifunk-gluon/gluon.git
    cd gluon
    git checkout origin/v2016.2.2
    git clone https://github.com/Freemesh-Ireland/site-fmie site
    make update

Build just the default target ar71xx-generic:

    NUM_CORES_PLUS_ONE=$(expr $(lscpu|grep -e '^CPU(s):'|xargs|cut -d" " -f2) + 1)
    make -j$NUM_CORES_PLUS_ONE

Build all targets and experimentals

    for TARGET in ar71xx-generic ar71xx-nand mpc85xx-generic x86-generic x86-kvm_guest x86-64 x86-xen_domu
    do
        make -j$NUM_CORES_PLUS_ONE GLUON_TARGET=$TARGET BROKEN=1
    done
