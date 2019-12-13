resource "aws_default_vpc" "default"{

}

data "aws_subnet_ids" "subnets" {
    vpc_id = aws_default_vpc.default.id
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "consul_server" {
  count = 3

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.consul-join.name
  vpc_security_group_ids = [aws_security_group.opsschool_consul.id]
  key_name               = aws_key_pair.server_key.key_name

  user_data = "${file("consul-server.sh")}"


  connection {
      type = "ssh"
      host = self.public_ip
      user = "ubuntu"
      private_key = tls_private_key.server_key.private_key_pem
  }

  provisioner "file" {
    source      = "ansible.pem"
    destination = "/tmp/ansible.pem"
  }

  tags = {
    Name = "Consul Server${count.index}",
    consul_server = "true"
  }
}


resource "aws_instance" "consul_apache_webserver" {
  count = 1

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.consul-join.name
  vpc_security_group_ids = [aws_security_group.opsschool_consul.id]
  key_name               = aws_key_pair.server_key.key_name
  user_data = "${file("consul-webserver.sh")}"

  connection {
      type = "ssh"
      host = self.public_ip
      user = "ubuntu"
      private_key = tls_private_key.server_key.private_key_pem
  }

  provisioner "file" {
    source      = "ansible.pem"
    destination = "/tmp/ansible.pem"
  }

  #    provisioner "remote-exec" {
  #    inline = [
  #      "sudo apt-get install apache2 -y",
  #      "sudo systemctl enable apache2",
  #      "sudo systemctl start apache2",
  #      "sudo chmod 777 /var/www/html/index.html"
  #    ]
  #  }

  #  provisioner "file" {
  #    source = "index.html"
  #    destination = "/var/www/html/index.html"
  #  }

  #  provisioner "remote-exec" {
  #    inline = [
  #      "sudo chmod 644 /var/www/html/index.html"
  #    ]
  #  }
  
  tags = {
    Name = "Consul apache webserver",
    consul_server = "true"
  }

}
