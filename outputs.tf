output "wg_eip" {
  description = "Public IP of WG Instance"
  value       = aws_eip.wg-kit_eip.public_ip
}
