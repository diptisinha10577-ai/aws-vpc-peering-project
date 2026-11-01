#!/usr/bin/env bash
# Generates ~/.ssh/config.ewb-lab from Terraform outputs and prints how to include it.
# Run from the repo root after `terraform apply`:   bash scripts/make-ssh-config.sh
set -euo pipefail

BASTION_IP="$(terraform -chdir=terraform output -raw bastion_public_ip)"
OUT="${HOME}/.ssh/config.ewb-lab"

mkdir -p "${HOME}/.ssh"
cat > "${OUT}" <<EOF
Host ewb-bastion
    HostName ${BASTION_IP}
    User ec2-user
    IdentityFile ~/.ssh/ewb-lab.pem
    IdentitiesOnly yes

Host ewb-app-a
    HostName 10.10.2.10
    User ec2-user
    IdentityFile ~/.ssh/ewb-lab.pem
    IdentitiesOnly yes
    ProxyJump ewb-bastion

Host ewb-app-b
    HostName 10.20.1.10
    User ec2-user
    IdentityFile ~/.ssh/ewb-lab.pem
    IdentitiesOnly yes
    ProxyJump ewb-bastion
EOF
chmod 600 "${OUT}"

echo "Wrote ${OUT}"
echo "Add this line at the TOP of ~/.ssh/config (once):"
echo "    Include ~/.ssh/config.ewb-lab"
echo "Make sure your key is in place:  chmod 400 ~/.ssh/ewb-lab.pem"
