#!/bin/bash

BASE=${PWD}

OUTPUT=/tmp/kemu_dbg/$$/
CONFIG=${OUTPUT}/config

INITFS=${BASE}/initfs/
STAGES=${BASE}/stages/
SCRIPT=${BASE}/script/
PROFILE=${BASE}/profile/

INITFS_FILE=${OUTPUT}/initfs

# ----------------
# |  1   |   2   |
# |      |       |
# |      |-------|
# |      | 3 | 4 |
# |      |   |   |
# ----------------

PROFILE_NAME=${1:-"x86_64.cfg"}
SESSION_NAME=${2:-"EmuDbg_$$"}
WINDOW_NAME=${3:-"EmuDbg"}

FIFO=${OUTPUT}/tmuxfifo

GDB=${OUTPUT}/gdb.sh
QEMU=${OUTPUT}/qemu.sh
GDB_PORT=$(expr 5000 + $$)

PTTY_1=
PTTY_2=
PTTY_3=
PTTY_4=

function tmux_is {
    if ! [ -z "$TMUX" ]
    then
        echo "TMUX session!"
    else
        echo "No TMUX!"
    fi
}

function session_create {
    tmux has-session -t ${SESSION_NAME} 2> /tmp/null
    if [ 0 -ne $? ]
    then
        tmux new-session -s ${SESSION_NAME} -d
        tmux rename-window -t ${SESSION_NAME} ${WINDOW_NAME}
    fi
}

function session_attach {
    tmux -2 attach -t ${SESSION_NAME}
}

function vpane_create {
    tmux split-window -t ${SESSION_NAME}:${1} -v -p ${2}
}

function hpane_create {
    tmux split-window -t ${SESSION_NAME}:${1} -h -p ${2}
}

function pane_select {
    tmux select-pane -t ${1}
}

function pane_cmd_execute {
    tmux send-key -t ${SESSION_NAME}:${1}.${2} "${3}" Enter
}

function layout_create {
    hpane_create 1 60 # Pane 2
    vpane_create 1 30 # Pane 3
    hpane_create 1 50 # Pane 4

    pane_select 2 # Activate Pane 2
}

function tty_get {
    pane_cmd_execute 1 1 "tty >> ${FIFO}"
    PTTY_1=$(cat ${FIFO})

    pane_cmd_execute 1 2 "tty >> ${FIFO}"
    PTTY_2=$(cat ${FIFO})

    pane_cmd_execute 1 3 "tty >> ${FIFO}"
    PTTY_3=$(cat ${FIFO})

    pane_cmd_execute 1 4 "tty >> ${FIFO}"
    PTTY_4=$(cat ${FIFO})
}

function dbg_print {
    echo "TTY_1:" ${PTTY_1}
    echo "TTY_2:" ${PTTY_2}
    echo "TTY_3:" ${PTTY_3}
    echo "TTY_4:" ${PTTY_4}
    echo
    echo "OUTPUT:" ${OUTPUT}
    echo "GDB_PORT:" ${GDB_PORT}
}

function fifo_create {
    if [ ! -p ${FIFO} ]
    then
        mkfifo ${FIFO}
    fi
}

function output_create {
    mkdir -p ${OUTPUT}
}

function phase_1_export {
    cat ${PROFILE}/${PROFILE_NAME}

    echo "E_BASE=${BASE}"

    echo "E_OUTPUT=${OUTPUT}"
    echo "E_CONFIG=${CONFIG}"
    echo "E_INITFS=${INITFS}"
    echo "E_STAGES=${STAGES}"
    echo "E_SCRIPT=${SCRIPT}"

    echo "E_INITFS_FILE=${INITFS_FILE}"

    echo "E_GDB=${GDB}"
    echo "E_QEMU=${QEMU}"
    echo "E_GDB_PORT=${GDB_PORT}"
} > ${CONFIG}

function phase_2_export {
    echo "E_PTTY_1=${PTTY_1}"
    echo "E_PTTY_2=${PTTY_2}"
    echo "E_PTTY_3=${PTTY_3}"
    echo "E_PTTY_4=${PTTY_4}"

    echo "E_SERIAL_TTY=${PTTY_2}"
    echo "E_MONITOR_TTY=${PTTY_4}"
} >> ${CONFIG}

function stages_run {
    for stage in ${STAGES}/*
    do
        echo ${stage}
        ${stage} ${CONFIG} ${PROFILE}/${PROFILE_NAME}

        if ! [ $? ]
        then
            echo "Error: " $?
            exit $?
        fi
    done
}

function dbg_run {
    pane_cmd_execute 1 1 "export E_CONFIG=${CONFIG}"
    pane_cmd_execute 1 2 "export E_CONFIG=${CONFIG}"
    pane_cmd_execute 1 3 "export E_CONFIG=${CONFIG}"
    pane_cmd_execute 1 4 "export E_CONFIG=${CONFIG}"

    pane_cmd_execute 1 1 "clear"
    pane_cmd_execute 1 2 "clear"
    pane_cmd_execute 1 3 "clear"
    pane_cmd_execute 1 4 "clear"

    pane_cmd_execute 1 2 "sleep 1000d"
    pane_cmd_execute 1 4 "sleep 1000d"

    pane_cmd_execute 1 3 ${QEMU}
    pane_cmd_execute 1 1 ${GDB}
}

function run {
    output_create
    phase_1_export
    stages_run

    fifo_create
    session_create
    layout_create

    tty_get
    phase_2_export

    dbg_print
    dbg_run

    # Let's go!
    session_attach
}

# Run
run
