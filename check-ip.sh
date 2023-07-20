#! /bin/bash

curl https://www.whatismyip.org/my-ip-address | grep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'
