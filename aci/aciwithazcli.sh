#!/bin/bash

subscription='e54229a3-0e6f-40b3-82a1-ae9cda6e2b81'
if [ -z $1 ]; then
    echo "No Subscription passed, exiting.."
    exit 1
else
    subscription=$1
fi
echo $subscription