# Reattach the internal ELBs to the master if they change
resource "aws_elb_attachment" "internal-master-elb" {
  count    = "${var.num_of_masters}"
  elb      = "${aws_elb.internal-master-elb.id}"
  instance = "${aws_instance.master.*.id[count.index]}"
}

# Internal Load Balancer Access
# Mesos Master, Zookeeper, Exhibitor, Adminrouter, Marathon
resource "aws_elb" "internal-master-elb" {
  name = "${data.template_file.cluster-name.rendered}-int-master-elb"
  internal = "true"

  subnets         = ["${aws_subnet.public.id}"]
  security_groups = ["${aws_security_group.master.id}","${aws_security_group.public_slave.id}", "${aws_security_group.private_slave.id}"]
  instances       = ["${aws_instance.master.*.id}"]

  listener {
    lb_port	      = 5050
    instance_port     = 5050
    lb_protocol       = "http"
    instance_protocol = "http"
  }

  listener {
    lb_port           = 2181
    instance_port     = 2181
    lb_protocol       = "tcp"
    instance_protocol = "tcp"
  }

  listener {
    lb_port           = 8181
    instance_port     = 8181
    lb_protocol       = "http"
    instance_protocol = "http"
  }

  listener {
    lb_port           = 80
    instance_port     = 80
    lb_protocol       = "tcp"
    instance_protocol = "tcp"
  }

  listener {
    lb_port           = 443
    instance_port     = 443
    lb_protocol       = "tcp"
    instance_protocol = "tcp"
  }

  listener {
    lb_port           = 8080
    instance_port     = 8080
    lb_protocol       = "http"
    instance_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 5
    target = "TCP:5050"
    interval = 30
  }

  lifecycle {
    ignore_changes = ["name"]
  }
}

# Reattach the public ELBs to the master if they change
resource "aws_elb_attachment" "public-master-elb" {
  count    = "${var.num_of_masters}"
  elb      = "${aws_elb.public-master-elb.id}"
  instance = "${aws_instance.master.*.id[count.index]}"
}

# Public Master Load Balancer Access
# Adminrouter Only
resource "aws_elb" "public-master-elb" {
  name = "${data.template_file.cluster-name.rendered}-pub-mas-elb"

  subnets         = ["${aws_subnet.public.id}"]
  security_groups = ["${aws_security_group.http-https.id}", "${aws_security_group.master.id}", "${aws_security_group.internet-outbound.id}"]
  instances       = ["${aws_instance.master.*.id}"]

  listener {
    lb_port           = 80
    instance_port     = 80
    lb_protocol       = "tcp"
    instance_protocol = "tcp"
  }

  listener {
    lb_port           = 443
    instance_port     = 443
    lb_protocol       = "tcp"
    instance_protocol = "tcp"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 5
    target = "TCP:5050"
    interval = 30
  }

  lifecycle {
    ignore_changes = ["name"]
  }
}

resource "aws_instance" "master" {
  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
  connection {
    # The default username for our AMI
    user = "${module.aws-tested-oses.user}"
    private_key = "${local.private_key}"
    agent = "${local.agent}"

    # The connection will use the local SSH agent for authentication.
  }

  root_block_device {
    volume_size = "${var.aws_master_instance_disk_size}"
  }

  count = "${var.num_of_masters}"
  instance_type = "${var.aws_master_instance_type}"
  iam_instance_profile = "${aws_iam_instance_profile.master.name}"

  ebs_optimized  = "true"

  tags {
    owner = "${coalesce(var.owner, data.external.whoami.result["owner"])}"
    expiration = "${var.expiration}"
    Name = "${data.template_file.cluster-name.rendered}-master-${count.index + 1}"
    cluster = "${data.template_file.cluster-name.rendered}"
    BDF-DCOS-POC-class = "${var.owner}-master"
  }

  # Lookup the correct AMI based on the region
  # we specified
  ami = "${module.aws-tested-oses.aws_ami}"

  # The name of our SSH keypair we created above.
  key_name = "${var.ssh_key_name}"

  # Our Security group to allow http, SSH, and outbound internet access only for pulling containers from the web
  vpc_security_group_ids = ["${aws_security_group.http-https.id}", "${aws_security_group.any_access_internal.id}", "${aws_security_group.ssh.id}", "${aws_security_group.internet-outbound.id}"]

  # We're going to launch into the same subnet as our ELB. In a production
  # environment it's more common to have a separate private subnet for
  # backend instances.
  subnet_id = "${aws_subnet.public.id}"


  lifecycle {
    ignore_changes = ["tags.Name", "tags.cluster"]
  }
}

output "Master ELB Public IP" {
  value = "${aws_elb.public-master-elb.dns_name}"
}

output "Master Public IPs" {
  value = ["${aws_instance.master.*.public_ip}"]
}

output "Master Private IPs" {
  value = ["${aws_instance.master.*.private_ip}"]
}