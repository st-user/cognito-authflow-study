#########################
# Cognito Identity Pool
#########################

# make cognito identity pool
resource "aws_cognito_identity_pool" "cognito_identity_pool" {
  identity_pool_name               = "my-cognito-identity-pool-name"
  allow_unauthenticated_identities = false

  developer_provider_name = var.cognito_provider_name
}
# Output the identity pool ID
output "cognito_identity_pool_id" {
  value = aws_cognito_identity_pool.cognito_identity_pool.id
}

# make IAM policy document 
# enabling action for AppConfig GetLatestConfiguration and StartConfigurationSession
data "aws_iam_policy_document" "appconfig_policy" {
  statement {
    effect = "Allow"
    actions = [
      "appconfig:GetLatestConfiguration",
      "appconfig:StartConfigurationSession",
    ]
    resources = ["arn:aws:appconfig:${var.aws_region}:${var.aws_account_id}:*"]
  }
}

# make IAM policy for "appconfig_policy"
resource "aws_iam_policy" "appconfig_policy" {
  name        = "appconfig_policy"
  description = "appconfig_policy"
  policy      = data.aws_iam_policy_document.appconfig_policy.json
}

data "aws_iam_policy_document" "cognito_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "mobileanalytics:PutEvents",
      "cognito-identity:*"
    ]
    resources = ["*"]
  }
}

# make IAM policy for "cognito_policy_document"
resource "aws_iam_policy" "cognito_policy" {
  name        = "cognito_policy"
  description = "cognito_policy"
  policy      = data.aws_iam_policy_document.cognito_policy_document.json
}

data "aws_iam_policy_document" "cognito_trust_relationship_policy_document" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = ["cognito-identity.amazonaws.com"]
    }
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]
    condition {
      test     = "StringEquals"
      variable = "cognito-identity.amazonaws.com:aud"
      values = [
        "${aws_cognito_identity_pool.cognito_identity_pool.id}"
      ]
    }
    condition {
      test     = "ForAnyValue:StringLike"
      variable = "cognito-identity.amazonaws.com:amr"
      values = [
        "authenticated"
      ]
    }
  }


}

# make IAM role for Cognito
resource "aws_iam_role" "cognito_role" {
  name               = "cognito-authenticated-user-role"
  assume_role_policy = data.aws_iam_policy_document.cognito_trust_relationship_policy_document.json
}

# attach appconfig_policy to the IAM role
resource "aws_iam_role_policy_attachment" "appconfig_policy_attachment" {
  role       = aws_iam_role.cognito_role.name
  policy_arn = aws_iam_policy.appconfig_policy.arn
}

# attach cognito_policy to the IAM role
resource "aws_iam_role_policy_attachment" "cognito_policy_attachment" {
  role       = aws_iam_role.cognito_role.name
  policy_arn = aws_iam_policy.cognito_policy.arn
}

# attach role to the identity pool
resource "aws_cognito_identity_pool_roles_attachment" "cognito_identity_pool_roles_attachment" {
  identity_pool_id = aws_cognito_identity_pool.cognito_identity_pool.id
  roles = {
    "authenticated" = aws_iam_role.cognito_role.arn
  }
}


###############
# AppConfig
###############

# make AppConfig application
resource "aws_appconfig_application" "appconfig_application" {
  name        = "my-appconfig-application"
  description = "my-appconfig-application"
}

# make AppConfig environment
resource "aws_appconfig_environment" "appconfig_environment" {
  name           = "Beta"
  application_id = aws_appconfig_application.appconfig_application.id
  description    = "Beta environment"
}

# make AppConfig configuration profile
resource "aws_appconfig_configuration_profile" "appconfig_configuration_profile" {
  name           = "my-appconfig-configuration-profile"
  application_id = aws_appconfig_application.appconfig_application.id
  description    = "my-appconfig-configuration-profile"
  location_uri   = "hosted"
}

# make AppConfig hosted configuration version
resource "aws_appconfig_hosted_configuration_version" "appconfig_hosted_configuration_version" {
  application_id           = aws_appconfig_application.appconfig_application.id
  configuration_profile_id = aws_appconfig_configuration_profile.appconfig_configuration_profile.configuration_profile_id
  content_type             = "application/json"
  description              = "my-appconfig-hosted-configuration-version"
  content                  = <<EOF
{
  "arrayValues": [
	1,2,3
  ],
  "stringValue": "ThisIsStringValue"
}
EOF
}
