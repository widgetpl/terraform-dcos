resource "aws_instance" "ansible" {
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

  instance_type = "${var.aws_master_instance_type}"
  iam_instance_profile = "${aws_iam_instance_profile.master.name}"

  ebs_optimized  = "true"

  tags {
    owner = "${coalesce(var.owner, data.external.whoami.result["owner"])}"
    expiration = "${var.expiration}"
    Name = "${data.template_file.cluster-name.rendered}-ansible"
    cluster = "${data.template_file.cluster-name.rendered}"
    BDF-DCOS-POC-class = "${var.owner}-ansible"
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

output "Ansible Public IPs" {
  value = ["${aws_instance.ansible.*.public_ip}"]
}

output "Ansible Private IPs" {
  value = ["${aws_instance.ansible.*.private_ip}"]
}