#!/bin/bash -e

tabs 4
clear
readonly VENV_DIR=$HOME/.venv

install_core() {
    local ppas="ppa.list"
    for ppa in $(cat $ppas)
    do
        sudo add-apt-repository -y $ppa
    done
    sudo apt-get update
    sudo apt-get install -y byobu htop vim vim-nox fonts-inconsolata openssh-server gtk2-engines-murrine \
        libcurl4-openssl-dev python-dev python3-dev build-essential cmake git linux-headers-generic \
        trimmomatic julia r-base  libhdf5-10 hdf5-tools \
        libopenblas-base libopenblas-dev gfortran g++ python-pip \
        samtools bedtools libpng-dev libjpeg8-dev libfreetype6-dev libxft-dev \
        libhdf5-dev libatlas3-base libatlas-dev python3-venv libxml2-dev libxslt-dev
    sudo apt-get upgrade -y && sudo apt-get dist-upgrade -y
    sudo update-alternatives --set libblas.so.3 /usr/lib/openblas-base/libblas.so.3
    sudo update-alternatives --set liblapack.so.3 /usr/lib/openblas-base/liblapack.so.3
}

install_google() {
    local base_url="https://dl.google.com/linux/direct"
        case `uname -i` in
            i386|i486|i586|i686)
            wget $base_url/google-chrome-beta_current_i386.deb
            ;;
        x86_64)
            wget $base_url/google-chrome-beta_current_amd64.deb
            ;;
    esac
    sudo apt-get install libappindicator1 libindicator7
    sudo dpkg -i google*.deb
    sudo apt-get install -fy
    rm google*.deb
}

setup_env() {
    local pydata="pydata.list"
    
    if [ -d $VENV_DIR/pydata3 ]
    then
        rm -rf $VENV_DIR/pydata3
    fi

    pyvenv $VENV_DIR/pydata3
    source $VENV_DIR/pydata3/bin/activate
    pip install -U pip
    cat $pydata | xargs -n 1 -L 1 pip install
    deactivate
}

setup_i3() {
    local dir="$(cd "$(dirname ${BASH_SOURCE[0]})" && pwd)"
    local wrapper="i3-wrapper.sh"
    local locker="lock.sh"
    echo "deb http://debian.sur5r.net/i3/ $(lsb_release -c -s) universe" | sudo tee -a /etc/apt/sources.list > /dev/null
    sudo apt-get update
    sudo apt-get install --allow-unauthenticated sur5r-keyring
    sudo apt-get update
    sudo apt-get install i3 compton imagemagick scrot nitrogen
    old_dir=$(pwd)
    cd $dir && cd ..
    if [ ! -d "$HOME/.i3" ]
    then
        ln -s conf/.i3 $HOME/.i3
    fi
    if [ ! -e "/bin/$wrapper" ]
    then
        sudo cp utils/$wrapper /bin
    fi
    if [ ! -e "/bin/$locker" ]
    then
        sudo cp utils/$locker /bin
    fi
    cd $old_dir
}

setup_vim() {
    local vim_dir="$HOME/.vim"
    if [ -d "$vim_dir" ]
    then
        rm -rf $vim_dir
    fi

    git clone https://github.com/VundleVim/Vundle.vim.git $vim_dir/bundle/Vundle.vim
    git clone https://github.com/Valloric/YouCompleteMe.git $vim_dir/bundle/YouCompleteMe
    cd $vim_dir/bundle/YouCompleteMe && git submodule update --init --recursive
    ./install.py --clang-completer
    cd -
}
    
show_help() {
    cat <<EOF
    usage: $0 options

    Bootstraps a new ubuntu GNOME install to upgrade to the latest GNOME version, 
    setup most common dev dependencies, python stack, google browser and plugin, 
    and i3 windows manager.

    OPTIONS:

    -h | --help     display this help text and exit
    -c | --core     upgrade GNOME to latest version, install dev dependencies,
                    install bioinformatics a nd data analysis packages
    -g | --google   install google chrome (beta channel) and google talk plugin
    -i | --i3       set up i3 windows manager and compton compositor
    -e | --env      set up python 3 virtualenv with data analysis/bioinformatics stack
                    as specified in pydata.list
    -v | --vim      setup vim plugin management (Vundle) and YouCompleteMe
                    autocompleter
    -a | --all      all of the above
EOF
}

readonly OPTS=`getopt -o acgeihv --long all,core,google,env,i3,help,vim -n 'bootstrap.sh' -- "$@"`

if [ $? != 0 ] ; then echo "Failed to parse options." >&2; exit 1; fi
eval set -- "$OPTS"

while true
do
    case "$1" in
        -a|--all)
            install_core
            install_google
            setup_env
            setup_i3
            shift
            ;;
        -c|--core)
            install_core
            shift
            ;;
        -g|--google)
            install_google
            shift
            ;;
        -e|--env)
            setup_env
            shift
            ;;
        -i|--i3)
            setup_i3
            shift
            ;;
        -h|--help)
            show_help
            shift
            ;;
        -v|--vim)
            setup_vim
            exit 1
            ;;
        * )
            break
            ;;
    esac
done

