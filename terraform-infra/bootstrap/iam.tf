
# Create EC2 IAM Role and  Instance Profile

resource "aws_iam_role" "ec2_role" {
  name = "${var.environment}-${var.project}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_agent" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.environment}-${var.project}-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_ssm_parameter" "ec2_role_arn" {
  name  = "/${var.environment}/ec2_role_arn"
  type  = "String"
  value = aws_iam_role.ec2_role.arn
}

resource "aws_ssm_parameter" "ec2_instance_profile" {
  name  = "/${var.environment}/ec2_instance_profile_name"
  type  = "String"
  value = aws_iam_instance_profile.ec2_instance_profile.name
}


# create CodeBuild IAM Role & attach Policy

resource "aws_iam_role" "codebuild_role" {
  name = "${var.environment}-${var.project}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "codebuild.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "codebuild_policy" {
  name = "${var.environment}-${var.project}-codebuild-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
        # for ecr access to pull and push docker images
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage"
        ],
        Resource = "*"
      },
      # for accessing remote s3 backend
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket"
        ],
        Resource = "arn:aws:s3:::${var.s3_bucket_name}"
      },
      {
        "Effect": "Allow",
        "Action": [
            "ec2:DescribeAvailabilityZones"
        ],
        "Resource": "*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource = "arn:aws:s3:::${var.s3_bucket_name}/*"
      },
      # for accessing dynamodb table for locking
      {
        Effect = "Allow",
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:DescribeTable"
        ],
        Resource = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.dynamodb_table_name}"
      },
      # for accessing ssm parameter store
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ],
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.environment}/*"
      },
      {
       Effect = "Allow",
       Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
       ],
       Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/infracost-api-key"
  },
      # for kms key to decrypt 
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ],
        Resource = local.kms_key_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_attach" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_policy.arn
}

resource "aws_ssm_parameter" "codebuild_role_arn" {
  name  = "/${var.environment}/codebuild_role_arn"
  type  = "String"
  value = aws_iam_role.codebuild_role.arn
}


# Create CodePipeline Role & Policy

resource "aws_iam_role" "codepipeline_role" {
  name = "${var.environment}-${var.project}-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "codepipeline.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "codepipeline_policy" {
  name = "${var.environment}-${var.project}-codepipeline-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
        # code build access 
      {
        Effect = "Allow",
        Action = [
          "codebuild:StartBuild",
          "codebuild:BatchGetBuilds",
          "codedeploy:CreateDeployment",
          "codedeploy:GetDeployment",
          "codedeploy:RegisterApplicationRevision"
        ],
        Resource = "*"
      },
      # for s3 artifacts access
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource = "arn:aws:s3:::${var.project}-*/*"
      },
      # codepipeline to pass permissions to codebuild and codedeploy
      {
        Effect = "Allow",
        Action = [
          "iam:PassRole"
        ],
        Resource = "*",
        Condition = {
          StringEqualsIfExists = {
            "iam:PassedToService" = [
              "codebuild.amazonaws.com",
              "codedeploy.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_attach" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_policy.arn
}

resource "aws_ssm_parameter" "codepipeline_role_arn" {
  name  = "/${var.environment}/codepipeline_role_arn"
  type  = "String"
  value = aws_iam_role.codepipeline_role.arn
}


# Create CodeDeploy Role & Policy

resource "aws_iam_role" "codedeploy_role" {
  name = "${var.environment}-${var.project}-codedeploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [ {
      Effect = "Allow",
      Principal = { Service = "codedeploy.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "codedeploy_policy" {
  name = "${var.environment}-${var.project}-codedeploy-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:Describe*",
          "autoscaling:Describe*",
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:CompleteLifecycleAction",
          "autoscaling:PutLifecycleHook",
          "autoscaling:DeleteLifecycleHook",
          "autoscaling:RecordLifecycleActionHeartbeat",
          "elasticloadbalancing:*"
        ],
        Resource = "*"
      }, 
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_attach" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = aws_iam_policy.codedeploy_policy.arn
}

resource "aws_ssm_parameter" "codedeploy_role_arn" {
  name  = "/${var.environment}/codedeploy_role_arn"
  type  = "String"
  value = aws_iam_role.codedeploy_role.arn
}
# create lambda role
resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.environment}-${var.project}-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}
# lambda basic execution role 
resource "aws_iam_role_policy_attachment" "lambda_basic_execution_attach" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
resource "aws_ssm_parameter" "lambda_execution_role_arn" {
  name  = "/${var.environment}/lambda_execution_role_arn"
  type  = "String"
  value = aws_iam_role.lambda_execution_role.arn
}


