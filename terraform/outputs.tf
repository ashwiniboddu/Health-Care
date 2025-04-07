output "healthcare_server_public_ip" {
  value = aws_eip.eip_healthcare.public_ip
}

output "monitoring_server_public_ip" {
  value = aws_eip.eip_monitoring.public_ip
}

output "private_key" {
  value     = tls_private_key.test_key.private_key_pem
  sensitive = true
}