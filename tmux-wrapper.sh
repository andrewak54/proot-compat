#!/bin/sh
umask 0077
exec env LD_PRELOAD=/home/akulov/libfakechown.so /usr/bin/tmux "$@"
