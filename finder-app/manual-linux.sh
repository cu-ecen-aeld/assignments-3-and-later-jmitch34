#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here
    echo "CROSS_COMPILE is: ${CROSS_COMPILE}gcc"
    echo "cleaning tree"
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper
    echo "setting config"
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
    echo "building kernel"
    set -x
    set -e
    set -u
    make -j$(nproc) ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
    echo "building modules"
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} modules
    echo "building DTBs"
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs
    echo "done with kernel build"
fi

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
mkdir -p ${OUTDIR}/rootfs
cd ${OUTDIR}/rootfs
mkdir init bin etc dev proc sys lib home lib64 usr mnt opt sbin
mkdir -p /lib/modules

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone https://github.com/mirror/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox...
    make distclean
    make defconfig
else
    cd busybox
fi

# Make and install busybox
echo "Building BusyBox with ARCH=${ARCH}, CROSS_COMPILE=${CROSS_COMPILE}"
make -j$(nproc) ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
echo "BusyBox build completed"

echo "Installing BusyBox to ${OUTDIR}/rootfs"
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} CONFIG_PREFIX=${OUTDIR}/rootfs install
echo "BusyBox installed successfully"

# Library dependencies
echo "Checking program interpreter in BusyBox binary"
${CROSS_COMPILE}readelf -a busybox | grep "program interpreter"

echo "Checking shared libraries required by BusyBox"
${CROSS_COMPILE}readelf -a busybox | grep "Shared library"

# Add library dependencies to rootfs
echo "Collecting library dependencies from toolchain sysroot"
SYSROOT=$(${CROSS_COMPILE}gcc -print-sysroot)
echo "SYSROOT determined as $SYSROOT"

echo "Copying libs from ${SYSROOT}/lib to ${OUTDIR}/rootfs/lib"
cp -a ${SYSROOT}/lib/* ${OUTDIR}/rootfs/lib/

echo "Copying libs from ${SYSROOT}/lib64 to ${OUTDIR}/rootfs/lib64"
cp -a ${SYSROOT}/lib64/* ${OUTDIR}/rootfs/lib64/

# Make device nodes
echo "Creating device nodes in ${OUTDIR}/rootfs/dev"
mknod -m 666 ${OUTDIR}/rootfs/dev/null c 1 3
mknod -m 600 ${OUTDIR}/rootfs/dev/console c 5 1
echo "Device nodes created"

# Clean and build the writer utility
echo "Building writer utility in ${FINDER_APP_DIR}"
cd ${FINDER_APP_DIR}
make CROSS_COMPILE=${CROSS_COMPILE}
echo "Writer utility build complete"

# Copy finder-related scripts and executables
echo "Copying finder-related files to ${OUTDIR}/rootfs/home/"
mkdir -p ${OUTDIR}/rootfs/home
cp -a writer finder-test.sh finder.sh conf/ ${OUTDIR}/rootfs/home/
cp autorun-qemu.sh ${OUTDIR}/rootfs/home/
echo "Finder files copied"

# Chown the root directory
echo "Taking ownership of ${OUTDIR}/rootfs with user $USER"
chown -R "$USER":"$USER" ${OUTDIR}/rootfs
echo "Ownership updated"

# Create initramfs.cpio.gz
echo "Creating initramfs.cpio from ${OUTDIR}/rootfs"
cd ${OUTDIR}/rootfs
pwd
find . | cpio -H newc -ov --owner="$USER":"$USER" > ${OUTDIR}/initramfs.cpio
echo "initramfs.cpio created at ${OUTDIR}/initramfs.cpio"

echo "Compressing initramfs.cpio to initramfs.cpio.gz"
cd ${OUTDIR}
gzip -f initramfs.cpio
echo "Compression completed: ${OUTDIR}/initramfs.cpio.gz"

echo "Adding the Image in outdir"
cp ${OUTDIR}/linux-stable/arch/arm64/boot/Image ${OUTDIR}/Image
echo "Kernel Image copied to ${OUTDIR}/Image"