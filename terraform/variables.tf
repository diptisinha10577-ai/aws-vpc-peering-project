variable "region" {
  description = "AWS Region for the whole lab (workbook example: Mumbai)."
  type        = string
  default     = "ap-south-1"
}

variable "student_name" {
  description = "Your name. Used for the Student tag on every resource."
  type        = string
}

variable "my_ip_cidr" {
  description = "Your current public IPv4 as a /32, e.g. 203.0.113.25/32. Run: curl -s https://checkip.amazonaws.com"
  type        = string

  validation {
    condition     = can(cidrhost(var.my_ip_cidr, 0)) && endswith(var.my_ip_cidr, "/32") && var.my_ip_cidr != "0.0.0.0/32"
    error_message = "Use your own public IPv4 with a /32 mask. Do not open SSH to 0.0.0.0/0."
  }
}

variable "key_name" {
  description = "Name of the EC2 key pair you created in the console (workbook: ewb-lab). The private .pem stays on your laptop."
  type        = string
  default     = "ewb-lab"
}

variable "instance_type" {
  description = "Small x86 instance type for all three hosts."
  type        = string
  default     = "t3.micro"
}

variable "enable_peering" {
  description = <<-EOT
    Phase switch.
    false = VPCs exist but are NOT peered (use this to capture the baseline ping failure).
    true  = create + accept peering and add the three peer routes.
  EOT
  type        = bool
  default     = false
}

variable "enable_app_b_icmp_rule" {
  description = "Set to false to run the controlled failure (removes the App-B ICMP echo rule from App-A). Set back to true to recover."
  type        = bool
  default     = true
}
