#variables for image generation
# create grub image for FVP (by Benshu: runninglinuxkenrel@126.com)

TOP_DIR=`pwd`
GRUB_FS_CONFIG_FILE=${TOP_DIR}/grub.cfg
BLOCK_SIZE=512
SEC_PER_MB=$((1024*2))
EXT3PART_UUID=535add81-5875-4b4a-b44a-464aee5f5cbd

create_grub_cfgfiles ()
{
	local fatpart_name="$1"

	mcopy -i  $fatpart_name -o ${GRUB_FS_CONFIG_FILE} ::/grub/grub.cfg
}

create_fatpart ()
{
	local fatpart_name="$1"  #Name of the FAT partition disk image
	local fatpart_size="$2"  #FAT partition size (in 512-byte blocks)

	dd if=/dev/zero of=$fatpart_name bs=$BLOCK_SIZE count=$fatpart_size
	mkfs.vfat $fatpart_name
	mmd -i $fatpart_name ::/EFI
	mmd -i $fatpart_name ::/EFI/BOOT
	mmd -i $fatpart_name ::/grub
	mcopy -i $fatpart_name bootaa64.efi ::/EFI/BOOT
	echo "======FAT partition image created"
}

create_diskimage ()
{
	local image_name="$1"
	local part_start="$2"
	local fatpart_size="$3"
	local ext3part_size="$4"

	(echo n; echo 1; echo $part_start; echo +$((fatpart_size-1)); echo 0700; echo w; echo y) | gdisk $image_name
	(echo n; echo 2; echo $((part_start+fatpart_size)); echo +$((ext3part_size-1)); echo 8300; echo w; echo y) | gdisk $image_name
	(echo x; echo c; echo 2; echo $EXT3PART_UUID; echo w; echo y) | gdisk $image_name
}


create_ext3part ()
{
	local ext3part_name="$1"  #Name of the ext3 partition disk image
	local ext3part_size=$2    #ext3 partition size (in 512-byte blocks)

	dd if=/dev/zero of=$ext3part_name bs=$BLOCK_SIZE count=$ext3part_size
	mkdir -p mnt
	#umount if it has been mounted
	if [[ $(findmnt -M "mnt") ]]; then
		fusermount -u mnt
	fi
	mkfs.ext3 -F $ext3part_name
	tune2fs -U $EXT3PART_UUID $ext3part_name

	fuse-ext2 $ext3part_name mnt -o rw+
	cp $TOP_DIR/../arch/arm64/boot/Image ./mnt
	# cp $TOP_DIR/ramdisk-busybox.img ./mnt
	sync
	fusermount -u mnt
	rm -rf mnt
	echo "====EXT3 partition image created"
}

prepare_disk_image ()
{
	echo
	echo
	echo "-------------------------------------"
	echo "Preparing disk image for grub boot"
	echo "-------------------------------------"

	#pushd $TOP_DIR/output
	local IMG_BB=grub-rlk.img
	local FAT_SIZE_MB=20
	local EXT3_SIZE_MB=200
	local PART_START=$((1*SEC_PER_MB))
	local FAT_SIZE=$((FAT_SIZE_MB*SEC_PER_MB))
	local EXT3_SIZE=$((EXT3_SIZE_MB*SEC_PER_MB))

	grep -q -F 'mtools_skip_check=1' ~/.mtoolsrc || echo "mtools_skip_check=1" >> ~/.mtoolsrc

	#Package images for grub
	rm -f $IMG_BB
	dd if=/dev/zero of=part_table bs=$BLOCK_SIZE count=$PART_START

	#Space for partition table at the top
	cat part_table > $IMG_BB

	#Create fat partition
	create_fatpart "fat_part" $FAT_SIZE
	create_grub_cfgfiles "fat_part"
	cat fat_part >> $IMG_BB

	#Create ext3 partition
	create_ext3part "ext3_part" $EXT3_SIZE
	cat ext3_part >> $IMG_BB

	#Space for backup partition table at the bottom (1M)
	cat part_table >> $IMG_BB

	# create disk image and copy into output folder
	create_diskimage $IMG_BB $PART_START $FAT_SIZE $EXT3_SIZE

	#remove intermediate files
	rm -f part_table
	rm -f fat_part
	rm -f ext3_part

	echo "Completed preparation of disk image for grub boot"
	echo "----------------------------------------------------"
}

if [ ! -f $TOP_DIR/../arch/arm64/boot/Image ]; then
	echo "canot find kernel image, pls run build_kernel command firstly!!"
	exit 1
fi

if [ -f $TOP_DIR/grub-rlk.img ]; then
	echo "delet old grub-rlk.img"
	rm grub-rlk.img
fi
	echo "start build grub image for FVP"

	prepare_disk_image
