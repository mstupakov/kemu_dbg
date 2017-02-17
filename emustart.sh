#!/bin/bash

BASE=${PWD}

export INITFS=${BASE}/initfs/
export STAGES=${BASE}/stages/
export OUTPUT=${BASE}/output/

# ----------------
# |  1   |   2   |
# |      |       |
# |      |-------|
# |      | 3 | 4 |
# |      |   |   |
# ----------------

SESSION_NAME=${1:-"EmuDbg_$$"}
WINDOW_NAME=${2:-"EmuDbg"}
FIFO_NAME=${3:-"/tmp/tmuxfifo_$$"}

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
    pane_cmd_execute 1 1 "tty >> ${FIFO_NAME}"
    PTTY_1=$(cat ${FIFO_NAME})

    pane_cmd_execute 1 2 "tty >> ${FIFO_NAME}"
    PTTY_2=$(cat ${FIFO_NAME})

    pane_cmd_execute 1 3 "tty >> ${FIFO_NAME}"
    PTTY_3=$(cat ${FIFO_NAME})

    pane_cmd_execute 1 4 "tty >> ${FIFO_NAME}"
    PTTY_4=$(cat ${FIFO_NAME})
}

function dbg_print {
    echo "TTY_1: " ${PTTY_1}
    echo "TTY_2: " ${PTTY_2}
    echo "TTY_3: " ${PTTY_3}
    echo "TTY_4: " ${PTTY_4}
}

function fifo_create {
    if [ ! -p ${FIFO_NAME} ]
    then
        mkfifo ${FIFO_NAME}
    fi
}

function stages_run {
    for stage in ${STAGES}/*
    do
        echo ${stage}
        ${stage}

        if ! [ $? ]
        then
            echo "Error: " $?
            exit $?
        fi
    done
}

function dbg_run {
    pane_cmd_execute 1 1 "clear"
    pane_cmd_execute 1 2 "clear"
    pane_cmd_execute 1 3 "clear"
    pane_cmd_execute 1 4 "clear"

    pane_cmd_execute 1 2 "sleep 1000d"
    pane_cmd_execute 1 4 "sleep 1000d"
}

function run {
    stages_run

    fifo_create
    session_create
    layout_create
    tty_get

    dbg_print
    dbg_run

    # Let's go!
    session_attach
}

# Run
run
