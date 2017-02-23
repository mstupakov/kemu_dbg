#!/bin/bash
source ${1}
source ${2}

function script_make {
    echo "#!/bin/bash"
    echo "source ${E_CONFIG}"

    cmd="-ex \"continue\" "
    cmd="-ex \"target remote :\${E_GDB_PORT}\" ${cmd}"
    cmd="-ex \"file \${P_VMLINUX}\" ${cmd}"
    cmd="-ex \"source \${E_SCRIPT}/py_gdb_kernel\" ${cmd}"
    cmd="-ex \"source \${E_SCRIPT}/gdb_kernel\" ${cmd}"
    cmd="KEMU_MODULE_DIR=${P_MODULE_DIR} ${P_GDB} ${P_GDB_PARAM} ${cmd}"
    echo "${cmd}" 
} > ${E_GDB}

function start {
    script_make
    chmod +x ${E_GDB}
}

start
