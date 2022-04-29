resource "aws_sns_topic" "sns_topic" {
  name = var.sns_topic_name
}

resource "aws_sns_topic_policy" "allow_publish_events" {
  arn = aws_sns_topic.sns_topic.arn

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Allow_Publish_Events",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "events.amazonaws.com",
          "cloudwatch.amazonaws.com"
        ]
      },
      "Action": "sns:Publish",
      "Resource": "${aws_sns_topic.sns_topic.arn}"
    }
  ]
}
EOF
}