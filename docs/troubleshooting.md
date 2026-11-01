# Troubleshooting

Check in this order: instance state, destination IP, subnet route table, security rule.

| Symptom | What to inspect |
|---|---|
| Bastion SSH times out | Bastion public IP changed after stop/start; your current public IP differs from the `/32` in the rule (update `my_ip_cidr` and re-apply); public subnet association; `0.0.0.0/0` route to the IGW |
| App-A SSH fails | App-A private IP; TCP 22 allowed from `10.10.1.10/32`; correct key and `ec2-user`; instance running |
| App-B SSH fails | `ewb-rt-a-public` needs `10.20.0.0/16 -> pcx`; VPC B needs `10.10.0.0/16 -> pcx`; App-B SSH source is the bastion private IP |
| Ping fails after peering | Both private route tables; correct pcx ID and Active state; ICMP echo rule on the destination; actual host IPs |
| Peering creation fails | CIDR overlap, including secondary CIDRs |
| `Permission denied (publickey)` | Wrong key pair, wrong `IdentityFile`, or wrong user. You did reach SSH authentication, so routing works |
| Fails only with custom ACLs | Check both directions, ICMP, and SSH ephemeral return ports. This lab uses default allow-all ACLs |

## Terraform-specific

- `my_ip_cidr` validation error: it must be your own IP with `/32`.
- Key pair not found: create `ewb-lab` in EC2 in the same Region first.
- Destroy hangs on security groups: wait for instance network interfaces to disappear, then re-run.
- Package updates on private hosts fail: expected, there is no internet egress. It does not mean peering is broken.
