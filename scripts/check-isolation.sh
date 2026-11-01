#!/usr/bin/env bash
# Isolation check (Test 05): confirms App-A and App-B have NO public IPv4.
# Needs the AWS CLI configured for the lab account/Region.
set -euo pipefail
REGION="${AWS_REGION:-ap-south-1}"

aws ec2 describe-instances --region "${REGION}" \
  --filters "Name=tag:Project,Values=EWB-VPC-Peering" "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].{Name:Tags[?Key==`Name`]|[0].Value,InstanceId:InstanceId,PrivateIp:PrivateIpAddress,PublicIp:PublicIpAddress}' \
  --output table
echo "Expected: ewb-bastion has a PublicIp; ewb-app-a and ewb-app-b show None."
