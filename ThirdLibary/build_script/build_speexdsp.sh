#!/bin/sh

#作者：康林
#参数:
#    $1:编译目标(android、windows_msvc、windows_mingw、unix)
#    $2:源码的位置 

#运行本脚本前,先运行 build_$1_envsetup.sh 进行环境变量设置,需要先设置下面变量:
#   RABBITIM_BUILD_TARGERT   编译目标（android、windows_msvc、windows_mingw、unix）
#   RABBITIM_BUILD_PREFIX=`pwd`/../${RABBITIM_BUILD_TARGERT}  #修改这里为安装前缀
#   RABBITIM_BUILD_SOURCE_CODE    #源码目录
#   RABBITIM_BUILD_CROSS_PREFIX   #交叉编译前缀
#   RABBITIM_BUILD_CROSS_SYSROOT  #交叉编译平台的 sysroot

set -e
HELP_STRING="Usage $0 PLATFORM (android|windows_msvc|windows_mingw|unix) [SOURCE_CODE_ROOT_DIRECTORY]"

case $1 in
    android|windows_msvc|windows_mingw|unix)
    RABBITIM_BUILD_TARGERT=$1
    ;;
    *)
    echo "${HELP_STRING}"
    exit 1
    ;;
esac

if [ -z "${RABBITIM_BUILD_PREFIX}" ]; then
    echo ". `pwd`/build_envsetup_${RABBITIM_BUILD_TARGERT}.sh"
    . `pwd`/build_envsetup_${RABBITIM_BUILD_TARGERT}.sh
fi

if [ -n "$2" ]; then
    RABBITIM_BUILD_SOURCE_CODE=$2
else
    RABBITIM_BUILD_SOURCE_CODE=${RABBITIM_BUILD_PREFIX}/../src/speexdsp
fi

CUR_DIR=`pwd`

#下载源码:
if [ ! -d ${RABBITIM_BUILD_SOURCE_CODE} ]; then
    if [ "TRUE" = "$RABBITIM_USE_REPOSITORIES" ]; then
        echo "git clone http://git.xiph.org/speexdsp.git  ${RABBITIM_BUILD_SOURCE_CODE}"
        #git clone -b 887ac10 http://git.xiph.org/speexdsp.git ${RABBITIM_BUILD_SOURCE_CODE}
        git clone http://git.xiph.org/speexdsp.git ${RABBITIM_BUILD_SOURCE_CODE}
    else
        echo "wget http://downloads.xiph.org/releases/speex/speexdsp-1.2rc3.tar.gz"
        mkdir -p ${RABBITIM_BUILD_SOURCE_CODE}
        cd ${RABBITIM_BUILD_SOURCE_CODE}
        wget http://downloads.xiph.org/releases/speex/speexdsp-1.2rc3.tar.gz
        tar xzf speexdsp-1.2rc3.tar.gz
        mv speexdsp-1.2rc3 ..
        rm -fr *
        cd ..
        mv -f speexdsp-1.2rc3 ${RABBITIM_BUILD_SOURCE_CODE}
    fi
fi

cd ${RABBITIM_BUILD_SOURCE_CODE}

if [ ! -f configure ]; then
    echo "sh autogen.sh"
    sh autogen.sh
fi

mkdir -p build_${RABBITIM_BUILD_TARGERT}
cd build_${RABBITIM_BUILD_TARGERT}
if [ -n "$RABBITIM_CLEAN" ]; then
    rm -fr *
fi

echo ""
echo "RABBITIM_BUILD_TARGERT:${RABBITIM_BUILD_TARGERT}"
echo "RABBITIM_BUILD_SOURCE_CODE:$RABBITIM_BUILD_SOURCE_CODE"
echo "CUR_DIR:`pwd`"
echo "RABBITIM_BUILD_PREFIX:$RABBITIM_BUILD_PREFIX"
echo "RABBITIM_BUILD_HOST:$RABBITIM_BUILD_HOST"
echo "RABBITIM_BUILD_CROSS_HOST:$RABBITIM_BUILD_CROSS_HOST"
echo "RABBITIM_BUILD_CROSS_PREFIX:$RABBITIM_BUILD_CROSS_PREFIX"
echo "RABBITIM_BUILD_CROSS_SYSROOT:$RABBITIM_BUILD_CROSS_SYSROOT"
echo "RABBITIM_BUILD_STATIC:$RABBITIM_BUILD_STATIC"
echo ""

echo "configure ..."

if [ "$RABBITIM_BUILD_STATIC" = "static" ]; then
    CONFIG_PARA="--enable-static --disable-shared"
else
    CONFIG_PARA="--disable-static --enable-shared"
fi
case ${RABBITIM_BUILD_TARGERT} in
    android)
        CONFIG_PARA="CC=${RABBITIM_BUILD_CROSS_PREFIX}gcc LD=${RABBITIM_BUILD_CROSS_PREFIX}ld"
        CONFIG_PARA="${CONFIG_PARA} --disable-shared -enable-static --with-gnu-ld --host=${RABBITIM_BUILD_CROSS_HOST}"
        CONFIG_PARA="${CONFIG_PARA} --with-sysroot=${RABBITIM_BUILD_CROSS_SYSROOT}"
        CFLAGS="-march=armv7-a -mfpu=neon --sysroot=${RABBITIM_BUILD_CROSS_SYSROOT}"
        CPPFLAGS="-march=armv7-a -mfpu=neon --sysroot=${RABBITIM_BUILD_CROSS_SYSROOT}"
        ;;
    unix)
        CONFIG_PARA="${CONFIG_PARA} --enable-vbr --enable-sse"
        ;;
    windows_msvc)
        echo "build_speex.sh don't support windows_msvc. please manually use msvc ide complie"
        cd $CUR_DIR
        exit 2
        ;;
    windows_mingw)
        case `uname -s` in
            Linux*|Unix*)
                CONFIG_PARA="${CONFIG_PARA} CC=${RABBITIM_BUILD_CROSS_PREFIX}gcc"
                CONFIG_PARA="${CONFIG_PARA} --host=${RABBITIM_BUILD_CROSS_HOST}"
                ;;
            *)
            ;;
        esac
        CONFIG_PARA="${CONFIG_PARA} --with-gnu-ld --enable-sse"
        ;;
    *)
        echo "${HELP_STRING}"
        cd $CUR_DIR
        exit 3
        ;;
esac

CONFIG_PARA="${CONFIG_PARA}"
echo "../configure --prefix=$RABBITIM_BUILD_PREFIX  --disable-examples  ${CONFIG_PARA} CFLAGS=\"${CFLAGS}\" CPPFLAGS=\"${CPPFLAGS}\""
../configure --prefix=$RABBITIM_BUILD_PREFIX  --disable-examples ${CONFIG_PARA} CFLAGS="${CFLAGS}" CPPFLAGS="${CPPFLAGS}"

echo "make install"
make ${RABBITIM_MAKE_JOB_PARA} && make install

cd $CUR_DIR
