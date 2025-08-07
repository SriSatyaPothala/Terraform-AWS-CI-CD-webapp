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
resource "aws_iam_role_policy" "ec2_ecr_pull" {
  name = "${var.environment}-${var.project}-ec2-ecr-pull"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ],
        Resource = "*"
      }
    ]
  })
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

# Create CodeBuild IAM Role & attach Policy
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
      # ECR access
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ],
        Resource = "*"
      },
      # load balancer and target group permissions
      {
      Effect = "Allow",
      Action = [
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:CreateTargetGroup",
          "elasticloadbalancing:DeleteTargetGroup",
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:DescribeTags",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeListenerAttributes",
          "elasticloadbalancing:DeleteTargetGroup"
      ],
    Resource = "*"
    },
      # CloudWatch Logs
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = [
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/*",
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/*:log-stream:*"
        ]
      },
      # S3 Backend
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
          "s3:PutObject",
          "s3:GetObject",
          "s3:PutObjectAcl"
        ],
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.project}-${var.environment}-artifact-bucket",
          "arn:aws:s3:::${var.project}-${var.environment}-artifact-bucket/*" ]

      },
      {
        Effect = "Allow",
        Action = ["s3:GetObject", "s3:PutObject"],
        Resource = "arn:aws:s3:::${var.s3_bucket_name}/*"
      },
      {
        Effect = "Allow",
        Action = [
          "cloudwatch:ListTagsForResource",
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:DeleteAlarms",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:TagResource",
          "cloudwatch:UntagResource"
        ],
      "Resource": "*"
      },
      # DynamoDB
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
      # SSM Parameters
      {
        Effect = "Allow",
        Action = ["ssm:GetParameter", "ssm:GetParameters"],
        Resource = [
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.environment}/*",
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/codebuild/dockerhub/password",
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/infracost-api-key"
        ]
      },
      # KMS Decryption
      {
        Effect = "Allow",
        Action = ["kms:Decrypt", "kms:GenerateDataKey"],
        Resource = local.kms_key_arn
      },
      # EC2 VPC + Address Management
      {
        Effect = "Allow",
        Action = [
          "ec2:CreateVpc",
          "ec2:DescribeVpcs",
          "ec2:CreateTags",
          "ec2:DeleteVpc",
          "ec2:AllocateAddress",
          "ec2:AssociateAddress",
          "ec2:ReleaseAddress",
          "ec2:CreateNatGateway",
          "ec2:ModifyVpcAttribute",
          "ec2:DeleteNatGateway",
          "ec2:Describe*",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:CreateSubnet",
          "ec2:DeleteSubnet",
          "ec2:CreateInternetGateway",
          "ec2:AttachInternetGateway",
          "ec2:DetachInternetGateway",
          "ec2:DeleteInternetGateway",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeSubnets",
          "ec2:DescribeRouteTables",
          "ec2:CreateRoute",
          "ec2:AssociateRouteTable",
          "ec2:CreateRouteTable",
          "ec2:DeleteRouteTable",
          "ec2:CreateLaunchTemplate",
          "ec2:ModifySubnetAttribute",
          "autoscaling:DescribeAutoScalingGroups"
          ],
        Resource = "*"
      },
      # lambda invocation permissions
      {
        Effect = "Allow",
        Action = [
           "lambda:AddPermission",
           "lambda:GetPolicy",
           "lambda:RemovePermission"
        ],
        Resource = "*"
      },
      # EventBridge
      {
        Effect = "Allow",
        Action = [
        "events:ListTagsForResource",
        "events:ListTargetsByRule",
        "events:PutRule",
        "events:PutTargets",
        "events:DescribeRule",
        "events:DeleteRule",
        "events:RemoveTargets"
        ],
        Resource = "arn:aws:events:${var.aws_region}:${data.aws_caller_identity.current.account_id}:rule/*"
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

# CodePipeline Role & Policy
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
      {
        Effect = "Allow",
        Action = [
          "codebuild:StartBuild",
          "codebuild:BatchGetBuilds",
          "codedeploy:CreateDeployment",
          "codedeploy:GetDeployment",
          "codedeploy:GetApplicationRevision",
          "codedeploy:RegisterApplicationRevision",
          "codedeploy:RegisterApplicationRevision"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "codestar-connections:UseConnection"
        ],
        Resource = "arn:aws:codeconnections:ap-south-1:345594588323:connection/649b992a-c628-4dd4-aab4-1e0b6d9efc38"
      },
      {
        Effect = "Allow",
        Action = [
          "codedeploy:GetDeploymentConfig"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = ["s3:GetObject", "s3:PutObject"],
        Resource = "arn:aws:s3:::${var.project}-*/*"
      },
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ],
        Resource = local.kms_key_arn
      },
      {
        Effect = "Allow",
        Action = ["iam:PassRole"],
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

# CodeDeploy Role
resource "aws_iam_role" "codedeploy_role" {
  name = "${var.environment}-${var.project}-codedeploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
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
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "ec2:RunInstances",
          "ec2:CreateTags",
          "iam:PassRole",
          "autoscaling:Describe*",
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:CompleteLifecycleAction",
          "autoscaling:PutLifecycleHook",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DeleteLifecycleHook",
          "sns:Publish",
          "cloudwatch:DescribeAlarms",
          "autoscaling:RecordLifecycleActionHeartbeat",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeLifecycleHooks",
          "autoscaling:PutInstanceInStandby",
          "autoscaling:DetachInstances",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "autoscaling:RecordLifecycleActionHeartbeat",
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:PutInstanceInService",
          "autoscaling:SuspendProcesses",
          "autoscaling:ResumeProcesses",
          "autoscaling:AttachInstances",
          "autoscaling:DetachInstances",
          "autoscaling:EnterStandby",
          "autoscaling:ExitStandby",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "elasticloadbalancing:*"

        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ],
        Resource = [
          "arn:aws:s3:::${var.project}-${var.environment}-artifact-bucket",
          "arn:aws:s3:::${var.project}-${var.environment}-artifact-bucket/*"
        ]
    },
    {
    Effect = "Allow",
    Action = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
      ],
      Resource = "*"
    }
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

# Lambda Role
resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.environment}-${var.project}-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution_attach" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
resource "aws_iam_role_policy" "lambda_codepipeline_access" {
  name = "${var.environment}-${var.project}-lambda-codepipeline-access"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "codepipeline:GetPipelineExecution"
        ],
        Resource = "arn:aws:codepipeline:ap-south-1:${data.aws_caller_identity.current.account_id}:${var.project}-pipeline"
      }
    ]
  })
}


resource "aws_ssm_parameter" "lambda_execution_role_arn" {
  name  = "/${var.environment}/lambda_execution_role_arn"
  type  = "String"
  value = aws_iam_role.lambda_execution_role.arn
}
