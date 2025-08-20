
resource "aws_s3_bucket" "avatars-r" {
  bucket = "grocerymate-avatars-r"

  tags = {
    Name        = "grocerymate-avatars-r"
    Environment = "Dev"
  }
}
