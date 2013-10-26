#!/sbin/busybox sh
#zImage_worker.sh
#armv7 executables
boot_tools=( mkbootimg mkbootfs unpackbootimg )
for check_file in ${boot_tools[@]}
do
	if [ ! -e /tmp/$check_file ]
		then
			echo "Error: '$check_dir' executable not found";
			exit;
	fi
done
MKBOOTIMG="/tmp/mkbootimg"
MKBOOTFS="/tmp/mkbootfs"
UNPACKBOOTIMG="/tmp/unpackbootimg"

#busybox executables
CAT="/sbin/busybox cat"
CHMOD="/sbin/busybox chmod"
CPIO="/sbin/busybox cpio"
CUT="/sbin/busybox cut"
ECHO="/sbin/busybox echo"
FLASH_IMAGE="/sbin/flash_image"
GREP="/sbin/busybox grep"
GZIP="/sbin/busybox gzip"
MKDIR="/sbin/busybox mkdir"
MV="/sbin/busybox mv"
RM="/sbin/busybox rm"

#chmod executables //safety measures
$CHMOD 755 $MKBOOTFS;
$CHMOD 755 $MKBOOTIMG;
$CHMOD 755 $UNPACKBOOTIMG;

#auto_search /proc/mtd for boot partition and pull boot.img
BOOT_PARTITION=`$CAT /proc/mtd | $GREP boot | $CUT -c1-4`;
$CAT /dev/mtd/$BOOT_PARTITION > /tmp/boot.img;

#unpack boot.img
$MKDIR -p "/tmp/unpack";
$UNPACKBOOTIMG -i /tmp/boot.img -o /tmp/unpack/;

#unpack ramdisk
$MKDIR -p "/tmp/boot";
cd "/tmp/boot";
$GZIP -dc /tmp/unpack/boot.img-ramdisk.gz | $CPIO -i;
cd "/";

#place_holder for hot_swapping ramdisk files

#repack ramdisk
$MKBOOTFS /tmp/boot | $GZIP > /tmp/unpack/boot.img-ramdisk-new.gz;

#get zImage extracted to /tmp
$MKDIR -p "/tmp/output";
$RM /tmp/unpack/boot.img-zImage;
$MV /tmp/zImage /tmp/unpack/boot.img-zImage;

#repack boot.img
$MKBOOTIMG --kernel /tmp/unpack/boot.img-zImage --ramdisk /tmp/unpack/boot.img-ramdisk-new.gz -o /tmp/boot_new.img --base `$CAT /tmp/unpack/boot.img-base`
$ECHO "boot.img ready!";

#remove unused files
$RM -rf /tmp/boot /tmp/boot.img /tmp/mkbootfs /tmp/mkbootimg /tmp/unpack /tmp/unpackbootimg

#flash new boot.img
if [ ! -e $FLASH_IMAGE ]
then
$ECHO "flash_image executable not found!"
else
$FLASH_IMAGE boot /tmp/boot_new.img
fi;

#remove unused boot.img
$RM -f /tmp/boot_new.img
