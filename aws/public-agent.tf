# Reattach the public ELBs to the agents if they change
resource "aws_elb_attachment" "public-agent-elb" {
  count    = "${var.num_of_public_agents}"
  elb      = "${aws_elb.public-agent-elb.id}"
  instance = "${aws_instance.public-agent.*.id[count.index]}"
}

# Public Agent Load Balancer Access
# Adminrouter Only
resource "aws_elb" "public-agent-elb" {
  name = "${data.template_file.cluster-name.rendered}-pub-agt-elb"

  subnets         = ["${aws_subnet.public.id}"]
  security_groups = ["${aws_security_group.public_slave.id}", "${aws_security_group.http-https.id}"]
  instances       = ["${aws_instance.public-agent.*.id}"]

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
    timeout = 2
    target = "HTTP:9090/_haproxy_health_check"
    interval = 5
  }

  lifecycle {
    ignore_changes = ["name"]
  }
}

resource "aws_instance" "public-agent" {
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
    volume_size = "${var.aws_public_agent_instance_disk_size}"
  }

  count = "${var.num_of_public_agents}"
  instance_type = "${var.aws_public_agent_instance_type}"
  iam_instance_profile = "${aws_iam_instance_profile.agent.name}"

  ebs_optimized = "true"

  tags {
    owner = "${coalesce(var.owner, data.external.whoami.result["owner"])}"
    expiration = "${var.expiration}"
    Name =  "${data.template_file.cluster-name.rendered}-pubagt-${count.index + 1}"
    cluster = "${data.template_file.cluster-name.rendered}"
    BDF-DCOS-POC-class = "${var.owner}-public-agent"
  }

  # Lookup the correct AMI based on the region
  # we specified
  ami = "${module.aws-tested-oses.aws_ami}"

  # The name of our SSH keypair we created above.
  key_name = "${var.ssh_key_name}"

  # Our Security group to allow http, SSH, and outbound internet access only for pulling containers from the web
  vpc_security_group_ids = ["${aws_security_group.public_slave.id}", "${aws_security_group.http-https.id}", "${aws_security_group.any_access_internal.id}", "${aws_security_group.ssh.id}", "${aws_security_group.internet-outbound.id}"]

  # We're going to launch into the same subnet as our ELB. In a production
  # environment it's more common to have a separate private subnet for
  # backend instances.
  subnet_id = "${aws_subnet.public.id}"

  lifecycle {
    ignore_changes = ["tags.Name"]
  }
}

output "Public Agent ELB Public IP" {
  value = "${aws_elb.public-agent-elb.dns_name}"
}

output "Public Agent Public IPs" {
  value = ["${aws_instance.public-agent.*.public_ip}"]
}

output "Public Agent Private IPs" {
  value = ["${aws_instance.public-agent.*.private_ip}"]
}