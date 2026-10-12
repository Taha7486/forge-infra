resource "aws_ecr_repository" "this" {
  for_each = toset(var.ecr_repositories)

  name = "${var.ecr_prefix}/${each.key}"

  # Every pushed image is tagged with its git SHA, so tags are never reused.
  image_tag_mutability = "IMMUTABLE"

  # AES256 is the AWS-owned default: no key of our own (rules file, no KMS).
  encryption_configuration {
    encryption_type = "AES256"
  }

  image_scanning_configuration {
    scan_on_push = false
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each = aws_ecr_repository.this

  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Untagged images expire after a day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep the newest five tagged images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 5
        }
        action = { type = "expire" }
      }
    ]
  })
}
