output "instance_id" {
  description = "ID of the jump box instance"
  value       = aws_instance.jumpbox.id
}

output "public_ip" {
  description = "Public IP address of the jump box"
  value       = aws_instance.jumpbox.public_ip
}

output "public_dns" {
  description = "Public DNS name of the jump box"
  value       = aws_instance.jumpbox.public_dns
}

output "security_group_id" {
  description = "ID of the jump box security group"
  value       = aws_security_group.jumpbox.id
}

output "private_key_pem" {
  description = "Private key for decrypting Windows password (if key pair was created)"
  value       = var.create_key_pair ? tls_private_key.jumpbox[0].private_key_pem : null
  sensitive   = true
}

output "key_pair_name" {
  description = "Name of the key pair"
  value       = var.create_key_pair ? aws_key_pair.jumpbox[0].key_name : var.key_name
}

output "password_decrypt_command" {
  description = "AWS CLI command to decrypt the Windows password"
  value       = "aws ec2 get-password-data --instance-id ${aws_instance.jumpbox.id} --priv-launch-key <path-to-private-key>"
}
