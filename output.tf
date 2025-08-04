output "instance_public_ips" {
  description = "Public IPs of EC2 instances"
  value       = aws_instance.splunk[*].public_ip
}

output "instance_names" {
  description = "Names of EC2 instances"
  value       = [for i in aws_instance.splunk : i.tags["Name"]]
}
