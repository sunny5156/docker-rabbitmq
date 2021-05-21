#!/bin/bash

export HOME=/usr/lib64/erlang
export PATH=$PATH:$HOME/bin
# call "rabbitmqctl stop" when exiting
trap "{ echo Stopping rabbitmq; rabbitmqctl stop; exit 0; }" EXIT

echo Starting rabbitmq
rabbitmq-server
