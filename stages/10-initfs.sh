#!/bin/bash
source ${1}

INIT_FS=${E_INITFS_FILE}
INIT_FS_DIR=${E_INITFS}

function start {
    cd ${INIT_FS_DIR}
    find . | cpio -o -H newc > ${INIT_FS}
    cd -
}

start
