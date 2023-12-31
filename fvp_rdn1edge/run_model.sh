FVP=./FVP_RD_N1_edge
arg=" -S -R"

config_file=" -C css.cmn600.mesh_config_file=/usr/local/FVP_RD_N1_edge/models/Linux64_GCC-9.3/RD_N1_E1_cmn600.yml"
nrsam=" -C css.cmn600.force_rnsam_internal=false --data css.scp.armcortexm7ct=scp_ramfw.bin@0x0BD80000 --data css.mcp.armcortexm7ct=mcp_ramfw.bin@0x0BF80000"
romloader=" -C css.mcp.ROMloader.fname=mcp_romfw.bin -C css.scp.ROMloader.fname=scp_romfw.bin -C css.trustedBootROMloader.fname=tf-bl1.bin"
flashloader=" -C board.flashloader0.fname=fip-uefi.bin -C board.flashloader1.fname=nor1_flash.img     -C board.flashloader1.fnameWrite=nor1_flash.img -C board.flashloader2.fname=nor2_flash.img -C board.flashloader2.fnameWrite=nor2_flash.img"
gic=" -C css.gic_distributor.ITS-device-bits=20 --min-sync-latency=0 --quantum=500"
image=" -C pci.pcie_rc.ahci0.ahci.image_path=grub-rlk.img  -C
board.virtioblockdevice.image_path=../rootfs_ubuntu_arm64.ext4"
uart_log=" -C css.scp.pl011_uart_scp.out_file=logs/uart-0-scp -C css.scp.pl011_uart_scp.unbuffered_output=1 -C css.mcp.pl011_uart0_mcp.out_file=logs/uart-0-mcp -C css.mcp.pl011_uart0_mcp.unbuffered_output=1 -C css.pl011_uart_ap.out_file=logs/uart-0-ap -C css.pl011_uart_ap.unbuffered_output=1 -C css.pl011_uart1_ap.out_file=logs/uart-1-ap -C css.pl011_uart1_ap.unbuffered_output=1 -C css.pl011_uart1_ap.flow_ctrl_mask_en=1 -C css.pl011_uart1_ap.enable_dc4=0"
#net=" -C board.hostbridge.userNetworking=true -C board.smsc_91c111.enabled=true"
#net=" -C board.hostbridge.userNetworking=true -C board.virtio_net.enabled=1"

if [ ! -f logs ]; then
	mkdir logs
fi

cmd="$FVP $arg $config_file $nrsam $romloader $flashloader $gic $image $uart_log"
echo "running FVP for rdn1edge:"
echo $cmd
eval $cmd


# /usr/local/FVP_RD_N1_edge/models/Linux64_GCC-9.3/FVP_RD_N1_edge -C css.cmn600.mesh_config_file=/usr/local/FVP_RD_N1_edge/models/Linux64_GCC-9.3/RD_N1_E1_cmn600.yml -C css.cmn600.force_rnsam_internal=false --data css.scp.armcortexm7ct=scp_ramfw.bin@0x0BD80000 --data css.mcp.armcortexm7ct=mcp_ramfw.bin@0x0BF80000 -C css.mcp.ROMloader.fname=mcp_romfw.bin -C css.scp.ROMloader.fname=scp_romfw.bin -C css.trustedBootROMloader.fname=tf-bl1.bin -C board.flashloader0.fname=fip-uefi.bin -C board.flashloader1.fname=nor1_flash.img -C board.flashloader1.fnameWrite=nor1_flash.img -C board.flashloader2.fname=nor2_flash.img -C board.flashloader2.fnameWrite=nor2_flash.img -S -R -C css.scp.pl011_uart_scp.out_file=rdn1edge/refinfra-571988-uart-0-scp_2023-12-29_14.47.12 -C css.scp.pl011_uart_scp.unbuffered_output=1 -C css.mcp.pl011_uart0_mcp.out_file=rdn1edge/refinfra-571988-uart-0-mcp_2023-12-29_14.47.12 -C css.mcp.pl011_uart0_mcp.unbuffered_output=1 -C css.pl011_uart_ap.out_file=rdn1edge/refinfra-571988-uart-0-nsec_2023-12-29_14.47.12 -C css.pl011_uart_ap.unbuffered_output=1 -C css.pl011_uart1_ap.out_file=rdn1edge/refinfra-571988-uart-0-sec_2023-12-29_14.47.12 -C css.pl011_uart1_ap.unbuffered_output=1 -C css.pl011_uart1_ap.flow_ctrl_mask_en=1 -C css.pl011_uart1_ap.enable_dc4=0 -C css.gic_distributor.ITS-device-bits=20 --min-sync-latency=0 --quantum=500 -C board.virtioblockdevice.image_path=grub-busybox.img


