resource "aws_ecr_repository" "repo" {
  name = var.ecr_repo_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

data aws_ecr_image prediction_image {
 repository_name = var.ecr_repo_name
 image_tag       = var.ecr_image_tag
}
