#!/usr/bin/env bash
# Cleanup + verification. SAVE YOUR EVIDENCE FIRST.
# Usage (from repo root):  bash scripts/cleanup.sh
set -euo pipefail
REGION="${AWS_REGION:-ap-south-1}"

echo "==> terraform destroy (removes instances, peering, routes, SGs, subnets, IGW, VPCs)"
terraform -chdir=terraform destroy

echo
echo "==> Leftover check by project tag in ${REGION} (all should be empty)"
echo "-- Instances not terminated:"
aws ec2 describe-instances --region "${REGION}" \
  --filters "Name=tag:Project,Values=EWB-VPC-Peering" \
  --query 'Reservations[].Instances[?State.Name!=`terminated`].InstanceId' --output text
echo "-- Volumes:"
aws ec2 describe-volumes --region "${REGION}" \
  --filters "Name=tag:Project,Values=EWB-VPC-Peering" \
  --query 'Volumes[].VolumeId' --output text
echo "-- Elastic IPs:"
aws ec2 describe-addresses --region "${REGION}" \
  --query 'Addresses[].AllocationId' --output text
echo "-- VPCs:"
aws ec2 describe-vpcs --region "${REGION}" \
  --filters "Name=tag:Project,Values=EWB-VPC-Peering" \
  --query 'Vpcs[].VpcId' --output text
echo "-- Peering connections:"
aws ec2 describe-vpc-peering-connections --region "${REGION}" \
  --filters "Name=tag:Project,Values=EWB-VPC-Peering" \
  --query 'VpcPeeringConnections[?Status.Code!=`deleted`].VpcPeeringConnectionId' --output text

echo
echo "Manual steps still to do:"
echo "  1. Delete the EC2 key pair 'ewb-lab' in the console if no longer needed."
echo "  2. Remove ~/.ssh/ewb-lab.pem and ~/.ssh/config.ewb-lab from your laptop if no longer needed."
echo "  3. Check Billing for remaining chargeable resources (usage reporting can lag)."
