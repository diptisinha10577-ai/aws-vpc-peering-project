# AWS VPC Peering Project (EWB Cloud Labs, Project 01)

Two private VPCs connected with VPC peering, administered through a single public bastion host using SSH ProxyJump.

- **Course:** AWS Architect Associate, EWB Courses
- **Region:** `ap-south-1` (Mumbai)
- **Tooling:** Terraform (infrastructure), OpenSSH (access), ping (verification)

## Architecture

```
Laptop --SSH/22--> Internet Gateway --> [VPC A 10.10.0.0/16]
                                         |- Public subnet  10.10.1.0/24  Bastion 10.10.1.10 (public IP)
                                         |- Private subnet 10.10.2.0/24  App-A   10.10.2.10 (no public IP)
                                                     |
                                                  Peering (pcx)
                                                     |
                                        [VPC B 10.20.0.0/16]  (no internet gateway)
                                         |- Private subnet 10.20.1.0/24  App-B   10.20.1.10 (no public IP)
```

| Resource | Name | CIDR / IP |
|---|---|---|
| VPC A | ewb-vpc-a | 10.10.0.0/16 |
| Public subnet A | ewb-a-public | 10.10.1.0/24 |
| Private subnet A | ewb-a-private | 10.10.2.0/24 |
| VPC B | ewb-vpc-b | 10.20.0.0/16 |
| Private subnet B | ewb-b-private | 10.20.1.0/24 |
| Bastion | ewb-bastion | 10.10.1.10 + public IPv4 |
| App-A | ewb-app-a | 10.10.2.10 |
| App-B | ewb-app-b | 10.20.1.10 |

## Design decisions

1. **Non-overlapping CIDRs.** Peering requires that the two VPC ranges do not overlap. `10.10.0.0/16` and `10.20.0.0/16` are disjoint.
2. **Routes on both sides.** Peering is only a link. Each side needs a route to the other VPC's CIDR, otherwise replies cannot return.
3. **Bastion needs a peering route too.** With ProxyJump, the bastion itself opens the SSH connection to App-B, so `ewb-rt-a-public` also needs `10.20.0.0/16 -> pcx`. The more specific route wins over `0.0.0.0/0`.
4. **App-B trusts the bastion's private IP.** App-B sees the connection coming from `10.10.1.10`, not from my laptop.
5. **Least-privilege security groups.** SSH to the bastion only from my `/32`. SSH to the apps only from the bastion `/32`. ICMP echo only between the two app hosts. Nothing open to `0.0.0.0/0`.
6. **No NAT gateway, no internet for private hosts.** Keeps cost low and the workloads genuinely private. Peering does not give VPC B internet access through VPC A.
7. **Hardening extras.** IMDSv2 required on all instances; root volumes are small gp3 with delete-on-termination.

## Repository layout

```
terraform/   main.tf, variables.tf, outputs.tf, versions.tf, terraform.tfvars.example
scripts/     make-ssh-config.sh, run-tests.sh, check-isolation.sh, cleanup.sh
docs/        concepts.md, troubleshooting.md, report-template.md
evidence/    screenshots and terminal output from MY run (add yours here)
```

## Prerequisites

- AWS lab account with permission for VPC, EC2 and key pairs; AWS CLI configured
- Terraform >= 1.5
- OpenSSH client (WSL on Windows)
- An EC2 key pair named `ewb-lab` created in the console, with `ewb-lab.pem` saved to `~/.ssh/ewb-lab.pem` (`chmod 400`). Do not commit it.

## How to reproduce (three phases, matching the workbook's evidence)

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars   # edit: student_name, my_ip_cidr (your IP/32)
terraform init
```

### Phase 1: network without peering (baseline)

```bash
terraform apply                  # enable_peering = false
cd .. && bash scripts/make-ssh-config.sh
ssh ewb-bastion                  # works
ssh ewb-app-a                    # works (VPC A local route)
bash scripts/run-tests.sh baseline   # Test 01: ping App-A -> App-B must FAIL
```

### Phase 2: peering + routes

Set `enable_peering = true` in `terraform.tfvars`, then:

```bash
cd terraform && terraform apply
cd .. && bash scripts/run-tests.sh forward   # Test 02
bash scripts/run-tests.sh reverse            # Test 03
bash scripts/run-tests.sh ssh-b              # Test 04
bash scripts/check-isolation.sh              # Test 05
```

### Phase 3: controlled failure and recovery

Set `enable_app_b_icmp_rule = false`, apply, then `bash scripts/run-tests.sh icmp-fail` (replies stop). Set it back to `true`, apply, then `bash scripts/run-tests.sh icmp-recover` (replies resume).

### Cleanup

```bash
bash scripts/cleanup.sh
```

## Results

Add your own results here after running the project (screenshots in `evidence/`):

| Test | Expected | My result |
|---|---|---|
| 01 Baseline ping A->B (before peering) | No replies | _fill in_ |
| 02 Forward ping A->B | 4 replies, 0% loss | _fill in_ |
| 03 Reverse ping B->A | 4 replies, 0% loss | _fill in_ |
| 04 SSH to App-B via bastion | Shell on App-B | _fill in_ |
| 05 No public IP on App-A / App-B | None | _fill in_ |
| Controlled failure and recovery | Stops, then resumes | _fill in_ |

## What I learned

_Write 3 to 4 sentences in your own words after finishing the lab._

## Cost and safety notes

Three t3.micro instances and one public IPv4 for a short time. Always run the cleanup and confirm in Billing. Never commit `.pem` files or Terraform state.
