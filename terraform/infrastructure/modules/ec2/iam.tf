
resource "aws_iam_role" "role" {
name = "ec2-iam-mlops-zoomcamp-${var.env}"
 path = "/"
 assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com",
          "s3.amazonaws.com"
        ]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "profile" {
 role = aws_iam_role.role.name
}

resource "aws_iam_role_policy_attachment" "ec2_attachment" {
 policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
 role = aws_iam_role.role.name
}

resource "aws_iam_role_policy_attachment" "s3_attachment" {
 policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
 role = aws_iam_role.role.name
}
