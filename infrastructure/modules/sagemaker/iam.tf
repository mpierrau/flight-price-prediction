resource "aws_iam_role" "sagemaker_role" {
 path = "/"
 assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "sagemaker.amazonaws.com",
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
 role = aws_iam_role.sagemaker_role.name
}

resource "aws_iam_role_policy_attachment" "sagemaker_attachment" {
 policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
 role = aws_iam_role.sagemaker_role.name
}

resource "aws_iam_role_policy_attachment" "s3_attachment" {
 policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
 role = aws_iam_role.sagemaker_role.name
}
