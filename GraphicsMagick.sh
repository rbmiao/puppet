#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#===============================================================================
#   SYSTEM REQUIRED:  CentOS / RedHat / Fedora
#   DESCRIPTION:  GraphicsMagick for LAMP
#   AUTHOR: Teddysun <i@teddysun.com>
#   VISIT:  http://teddysun.com/lamp
#===============================================================================

cur_dir=`pwd`
cd $cur_dir

PHP_PREFIX='/usr/local/php'
GraphicsMagick_Ver='GraphicsMagick-1.3.20'
GraphicsMagick_ext_Ver='gmagick-1.1.7RC2'

# get PHP version
PHP_VER=$(php -r 'echo PHP_VERSION;' 2>/dev/null | awk -F. '{print $1$2}')
if [ $? -ne 0 -o -z $PHP_VER ]; then
    echo "Error:PHP looks like not installed, please check it and try again."
    exit 1
fi

# get PHP extensions date
if [ $PHP_VER -eq 53 ]; then
    extDate='20090626'
elif [ $PHP_VER -eq 54 ]; then
    extDate='20100525'
elif [ $PHP_VER -eq 55 ]; then
    extDate='20121212'
fi

# Make sure only root can run our script
function rootness(){
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root" 1>&2
        exit 1
    fi
}

# Download files
function download_files(){
    if [ -s $1 ]; then
        echo "$1 [found]"
    else
       echo "$1 not found!!!download now......"
       if ! wget --tries=3 http://lamp.teddysun.com/files/$1; then
           echo "Failed to download $1, please download it to "$cur_dir" directory manually and try again."
           exit 1
       fi
    fi
}

# Install graphicsmagick software
function install_graphicsmagick_soft(){
    cd $cur_dir/untar/$GraphicsMagick_Ver
    ./configure --enable-shared
    make && make install
}

# Install gmagick extension
function install_graphicsmagick_ext(){
    echo "gmagick extension install start..."
    cd $cur_dir/untar/$GraphicsMagick_ext_Ver
    $PHP_PREFIX/bin/phpize
    ./configure --with-php-config=$PHP_PREFIX/bin/php-config
    make && make install
    if [ ! -f $PHP_PREFIX/php.d/gmagick.ini ]; then
        echo "graphicsmagick configuration not found, create it!"
        cat > $PHP_PREFIX/php.d/gmagick.ini<<-EOF
[gmagick]
extension = /usr/local/php/lib/php/extensions/no-debug-non-zts-${extDate}/gmagick.so
EOF
    fi
    # Clean up
    cd $cur_dir
    rm -rf $cur_dir/untar/
    /etc/init.d/httpd restart
    echo "gmagick extension install completed..."
exit
}

# Install graphicsmagick
function install_graphicsmagick(){
    rootness
    download_files "${GraphicsMagick_Ver}.tar.gz"
    download_files "${GraphicsMagick_ext_Ver}.tgz"
    if [ ! -d $cur_dir/untar/ ]; then
        mkdir -p $cur_dir/untar/
    fi
    tar xzf $GraphicsMagick_Ver.tar.gz -C $cur_dir/untar/
    tar xzf $GraphicsMagick_ext_Ver.tgz -C $cur_dir/untar/
    install_graphicsmagick_soft
    install_graphicsmagick_ext
}

action=$1
[ -z $1 ] && action=install
case "$action" in
install)
    install_graphicsmagick
    ;;
*)
    echo "Usage: `basename $0` {install}"
    ;;
esac
