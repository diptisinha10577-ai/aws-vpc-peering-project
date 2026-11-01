# Concepts explained simply

## Why is the return route needed?
A route table decides where a packet goes next. App-A sends a ping to `10.20.1.10` using the `10.20.0.0/16 -> pcx` route. App-B receives it and replies to `10.10.2.10`. Without `10.10.0.0/16 -> pcx` in VPC B's route table, the reply has no path back and the ping fails. Both directions need routes.

## Why is the App-B SSH source the bastion's private IP?
With ProxyJump, my laptop connects to the bastion, and then the bastion opens a second SSH connection to App-B over the peering link. App-B sees the connection coming from `10.10.1.10`, not from my laptop's public IP.

## Why does Active peering not guarantee a successful ping?
Peering only creates the link. Traffic also needs routes on both sides, security group rules that allow it (ICMP/SSH), and network ACLs that do not block it. Any missing piece breaks the path.

## Can VPC B use VPC A's internet gateway over peering?
No. Peering does not forward traffic to an internet gateway (no edge-to-edge routing). VPC B has no internet access in this lab.

## Why does the public subnet need a peering route?
The bastion lives in the public subnet and starts the connection to App-B. Its subnet's route table must know that `10.20.0.0/16` goes through the peering connection. The more specific `/16` route beats the `0.0.0.0/0` internet route.

## Why must the CIDRs not overlap?
AWS cannot decide where to send traffic for an address that exists in both VPCs, so it refuses to create the peering. Different subnet ranges do not fix overlapping VPC CIDRs.

## Peering is non-transitive
A-B and A-C does not give B-C. Each pair needs its own peering connection.

## Security groups are stateful
If an inbound request is allowed, the reply is allowed automatically. That is why only inbound rules are needed in this lab.
