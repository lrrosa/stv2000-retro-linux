echo "STV-2000: iniciando Alpine Linux"
if fatload mmc 0 0x1000000 u-boot.ext; then osd clear; osd close; go 0x1000000; fi;
if fatload usb 0 0x1000000 u-boot.ext; then osd clear; osd close; go 0x1000000; fi;
setenv kernel_addr_r 0x11000000
setenv ramdisk_addr_r 0x18000000
setenv fdt_addr_r 0x10e00000
for devtype in mmc usb; do for devnum in 0 1 2 3; do if test -e ${devtype} ${devnum} uEnv.txt; then load ${devtype} ${devnum} 0x1000000 uEnv.txt; env import -t 0x1000000 ${filesize}; setenv bootargs ${APPEND}; if printenv mac; then setenv bootargs ${bootargs} mac=${mac}; elif printenv eth_mac; then setenv bootargs ${bootargs} mac=${eth_mac}; elif printenv ethaddr; then setenv bootargs ${bootargs} mac=${ethaddr}; fi; if load ${devtype} ${devnum} ${kernel_addr_r} ${LINUX}; then if load ${devtype} ${devnum} ${ramdisk_addr_r} ${INITRD}; then if load ${devtype} ${devnum} ${fdt_addr_r} ${FDT}; then fdt addr ${fdt_addr_r}; booti ${kernel_addr_r} ${ramdisk_addr_r} ${fdt_addr_r}; fi; fi; fi; fi; done; done;
