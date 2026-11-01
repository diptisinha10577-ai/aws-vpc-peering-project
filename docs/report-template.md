# Report template: YourName_EWB_VPC_Peering.pdf

Fill every placeholder with YOUR OWN screenshots and output from your run, then export to PDF. Label each screenshot with host, test and result. Do not include `.pem` keys, passwords or access tokens.

---

## Cover
- Name: ______  Batch: ______
- Project: AWS VPC Peering
- Region: ap-south-1 (Mumbai)
- Completion date: ______

## 1. Architecture and inventory
[Insert architecture diagram]

| Resource | Name | Actual ID | CIDR / IP |
|---|---|---|---|
| VPC A | ewb-vpc-a | vpc-______ | 10.10.0.0/16 |
| VPC B | ewb-vpc-b | vpc-______ | 10.20.0.0/16 |
| Public subnet A | ewb-a-public | subnet-______ | 10.10.1.0/24 |
| Private subnet A | ewb-a-private | subnet-______ | 10.10.2.0/24 |
| Private subnet B | ewb-b-private | subnet-______ | 10.20.1.0/24 |
| Internet gateway | ewb-igw-a | igw-______ | |
| Route tables | ewb-rt-a-public / a-private / b-private | rtb-______ | |
| Peering | ewb-a-b-peer | pcx-______ | |
| Bastion | ewb-bastion | i-______ | 10.10.1.10 + public IP ______ |
| App-A | ewb-app-a | i-______ | 10.10.2.10 |
| App-B | ewb-app-b | i-______ | 10.20.1.10 |

(Tip: `terraform output inventory` prints most of these IDs.)

## 2. Subnets and route tables
[Screenshot: subnets with CIDRs] [Screenshot: ewb-rt-a-public routes + association] [Screenshot: ewb-rt-a-private] [Screenshot: ewb-rt-b-private]

## 3. Peering connection
[Screenshot: ewb-a-b-peer, Active, both VPC IDs]

## 4. Security group inbound rules
[Screenshot: ewb-sg-bastion] [Screenshot: ewb-sg-app-a] [Screenshot: ewb-sg-app-b]

## 5. Test evidence
| Test | Screenshot / output | Result |
|---|---|---|
| 01 Baseline: App-A ping App-B before peering | [paste] | No replies |
| 02 Forward: App-A to App-B | [paste] | ___ replies, ___% loss |
| 03 Reverse: App-B to App-A | [paste] | ___ replies, ___% loss |
| 04 SSH to App-B through bastion | [paste] | Shell obtained |
| 05 Isolation: no public IPv4 on App-A/App-B | [paste] | |

## 6. Controlled failure and recovery
[Screenshot: ICMP rule removed, ping fails] [Screenshot: rule restored, ping works]

Explanation (write in your own words): ______

## 7. Forward path and return path
Explain in your own words how a packet goes from App-A to App-B and back. See `docs/concepts.md` for the ideas, but describe what you saw.

## 8. Cleanup evidence
[Screenshot: terraform destroy complete] [Screenshot: tag-filtered checks empty] [Screenshot: Billing]

## 9. What I learned
______
