output "consul_server_public_address" {
    value = aws_instance.consul_server.*.public_ip
}
output "consul_apache_webserver_public_addresses" {
    value = aws_instance.consul_apache_webserver.*.public_ip
}