#!/bin/bash
source ${1}

function script_make {
    echo "#!/bin/bash"
    echo "source ${E_CONFIG}"

    cmd="-nographic "
    cmd="-serial \${E_SERIAL_TTY} ${cmd}"
    cmd="-monitor \${E_MONITOR_TTY} ${cmd}"
    cmd="-append 'earlyprintk=/dev/ttyS0 console=/dev/ttyS0' ${cmd}"
    cmd="-kernel \${P_QEMU_BZIMAGE} ${cmd}"
    cmd="-initrd \${E_INITFS_FILE} ${cmd}"
    cmd="-m \${P_QEMU_MEMORY} ${cmd}"

    cmd="${P_QEMU} ${P_QEMU_EXTRA_PARAM} ${cmd}"
    echo "${cmd}" 
} > ${E_QEMU}

function start {
    script_make
    chmod +x ${E_QEMU}
}

start
