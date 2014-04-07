#!/bin/bash -i

TSR_CONFIG_FILE=/etc/tsuru/tsuru.conf

screen -X -S api quit
screen -X -S collector quit
screen -X -S ssh quit

screen -S api -d -m tsr api --config=$TSR_CONFIG_FILE
screen -S collector -d -m tsr collector --config=$TSR_CONFIG_FILE
screen -S ssh -d -m tsr docker-ssh-agent -l 0.0.0.0:4545 -u ubuntu -k /var/lib/tsuru/.ssh/id_rsa
