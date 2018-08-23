resource "aws_key_pair" "main" {
  key_name_prefix = "${var.prefix}"
  public_key      = "${tls_private_key.ssh.public_key_openssh}"
}

resource "aws_key_pair" "runners" {
  key_name_prefix = "${var.prefix}-runners"
  public_key      = "${tls_private_key.runners-ssh.public_key_openssh}"
}

resource "aws_instance" "ecs_instances" {
  ami                         = "${data.aws_ami.amazon-ecs-optimized.id}"
  instance_type               = "${var.ecs_instances["instance_type"]}"
  key_name                    = "${aws_key_pair.main.key_name}"
  iam_instance_profile        = "${aws_iam_instance_profile.ecs.name}"
  user_data                   = "${data.template_file.ecs_instances.rendered}"
  associate_public_ip_address = true
  subnet_id                   = "${aws_subnet.public.1.id}"
  availability_zone           = "${aws_subnet.public.1.availability_zone}"
  vpc_security_group_ids      = [
    "${aws_security_group.allow_all_egress.id}",
    "${aws_security_group.allow_ssh.id}",
    "${aws_security_group.allow_all_public_subnets_vpc.id}"
  ]
  lifecycle {
    ignore_changes        = ["ami"]
    create_before_destroy = true
  }
}

resource "aws_ebs_volume" "ecs_instances" {
  availability_zone = "${aws_instance.ecs_instances.availability_zone}"
  size              = "${var.gitlab_servers["volume_size"]}"
  type              = "gp2"
}

resource "aws_volume_attachment" "ecs_instances" {
  device_name   = "/dev/xvdb"
  force_detach  = true
  volume_id     = "${aws_ebs_volume.ecs_instances.id}"
  instance_id   = "${aws_instance.ecs_instances.id}"
}
