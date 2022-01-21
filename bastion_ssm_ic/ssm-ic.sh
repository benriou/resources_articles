#!/bin/bash

export INSTANCE=$(aws ec2 describe-instances --filters Name=tag:Name,Values=$1 | jq -r '.Reservations[].Instances[] | select(.State.Name == "running") | .InstanceId')

export AZ=$(aws ec2 describe-instances --filters Name=tag:Name,Values=$1 | jq -r '.Reservations[].Instances[] | select(.State.Name == "running") | .Placement.AvailabilityZone')

ssh-keygen -t rsa -f /tmp/ssm_ic -N ''>/dev/null

aws ec2-instance-connect send-ssh-public-key --instance-id $INSTANCE --availability-zone $AZ --instance-os-user ec2-user --ssh-public-key file:///tmp/ssm_ic.pub > /dev/null

aws ssm start-session --target $INSTANCE --document-name AWS-StartSSHSession --region=eu-west-1 --parameters 'portNumber=22'

rm /tmp/ssm_ic* 2>/dev/null

