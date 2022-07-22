
data "aws_route53_zone" "main" {
  name         = var.domain
  private_zone = false
}

resource "aws_ses_domain_identity" "ses_domain" {
  domain = var.domain
}

resource "aws_ses_email_identity" "example" {
  count = var.email != null ? 1 : 0 
  email = var.email
}

resource "aws_ses_domain_mail_from" "main" {
  domain           = aws_ses_domain_identity.ses_domain.domain
  mail_from_domain = "mail.${var.domain}"
}

resource "aws_route53_record" "amazonses_verification_record" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "_amazonses.${var.domain}"
  type    = "TXT"
  ttl     = "600"
  records = [join("", aws_ses_domain_identity.ses_domain.*.verification_token)]
}

resource "aws_ses_domain_dkim" "ses_domain_dkim" {
  domain = join("", aws_ses_domain_identity.ses_domain.*.domain)
}

resource "aws_route53_record" "amazonses_dkim_record" {
  count   = 3
  zone_id = data.aws_route53_zone.main.zone_id 
  name    = "${element(aws_ses_domain_dkim.ses_domain_dkim.dkim_tokens, count.index)}._domainkey.${var.domain}"
  type    = "CNAME"
  ttl     = "600"
  records = ["${element(aws_ses_domain_dkim.ses_domain_dkim.dkim_tokens, count.index)}.dkim.amazonses.com"]
}

resource "aws_route53_record" "spf_mail_from" {
  zone_id = data.aws_route53_zone.main.zone_id 
  name    = aws_ses_domain_mail_from.main.mail_from_domain
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com -all"]
}

resource "aws_route53_record" "spf_domain" {
  zone_id = data.aws_route53_zone.main.zone_id   
  name    = var.domain
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com -all"]
}
