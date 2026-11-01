output "bastion_public_ip" {
  description = "Put this in ~/.ssh/config as BASTION_PUBLIC_IP"
  value       = aws_instance.bastion.public_ip
}

output "inventory" {
  description = "IDs to record for Checkpoints 01-04 and the report inventory table"
  value = {
    vpc_a_id          = aws_vpc.a.id
    vpc_b_id          = aws_vpc.b.id
    subnet_a_public   = aws_subnet.a_public.id
    subnet_a_private  = aws_subnet.a_private.id
    subnet_b_private  = aws_subnet.b_private.id
    igw_id            = aws_internet_gateway.a.id
    rt_a_public       = aws_route_table.a_public.id
    rt_a_private      = aws_route_table.a_private.id
    rt_b_private      = aws_route_table.b_private.id
    sg_bastion        = aws_security_group.bastion.id
    sg_app_a          = aws_security_group.app_a.id
    sg_app_b          = aws_security_group.app_b.id
    bastion_id        = aws_instance.bastion.id
    app_a_id          = aws_instance.app_a.id
    app_b_id          = aws_instance.app_b.id
    peering_id        = try(aws_vpc_peering_connection.a_b[0].id, "not created yet (enable_peering = false)")
  }
}

output "private_ips" {
  value = {
    bastion = aws_instance.bastion.private_ip
    app_a   = aws_instance.app_a.private_ip
    app_b   = aws_instance.app_b.private_ip
  }
}
