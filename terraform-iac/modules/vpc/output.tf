output "vpc_id" {
  value = aws_vpc.this.id
}
output "private_db_subnet_ids" {
  value = aws_subnet.database[*].id
}
output "private_db_subnet_name" {
  value = aws_subnet.database[*].tags["Name"]
}
output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}
output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}