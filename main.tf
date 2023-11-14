resource "aws_network_interface" "selected" {
  subnet_id       = local.subnet_id
  private_ips     = ["172.31.16.20"]
  security_groups = [aws_security_group.instance_sg_node_exporter.id]
  tags = {
    Name = "network interface"
  }
}

resource "aws_instance" "instance_prometheus_grafana" {
  ami                    = local.instance_ami
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance_sg_prometheus_server.id]
  key_name               = "vockey"

  user_data = file("install_prometheus_grafana.sh")

  tags = {
    Name = "instance_prometheus_grafana"
  }
}

resource "aws_instance" "instance_node_exporter" {
  ami           = local.instance_ami
  instance_type = "t2.micro"
  key_name      = "vockey"
  network_interface {
    network_interface_id = aws_network_interface.selected.id
    device_index         = 0
  }

  user_data = "${file("install_node_exporter.sh")}"

  tags = {
    Name = "instance_node_exporter"
  }
}
