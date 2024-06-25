################################################################################
# CodePipeline Role
################################################################################

data "aws_iam_policy" "ec2_full_access" {
  name = "AmazonEC2FullAccess"
}

data "aws_iam_policy" "r53_domain_access" {
  name = "AmazonRoute53DomainsFullAccess"
}

data "aws_iam_policy" "ecs_full_access" {
  name = "AmazonECS_FullAccess"
}

resource "aws_iam_role" "codepipeline_role" {
  name               = "${var.repository_name}-github-pipeline-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_ec2_full_access" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = data.aws_iam_policy.ec2_full_access.arn
}

resource "aws_iam_role_policy_attachment" "attach_r53_domain_access" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = data.aws_iam_policy.r53_domain_access.arn
}

resource "aws_iam_role_policy_attachment" "attach_ecs_full_access" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = data.aws_iam_policy.ecs_full_access.arn
}
resource "aws_iam_role_policy" "codepipeline_policy" {
  #checkov:skip=CKV_AWS_290:Permissions for CodeBuild to start builds.
  #checkov:skip=CKV_AWS_355:Permissions for CodeBuild to get builds.
  #checkov:skip=CKV_AWS_290:Permissions for CodeBuild to get builds.
  name = "codepipeline_policy"
  role = aws_iam_role.codepipeline_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObjectAcl",
        "s3:PutObject"
      ],
      "Resource": [
        "${var.artifacts_bucket_arn}",
        "${var.artifacts_bucket_arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:DescribeKey",
        "kms:GenerateDataKey*",
        "kms:Encrypt",
        "kms:ReEncrypt*",
        "kms:Decrypt"
      ],
      "Resource": "${var.artifacts_bucket_encryption_key_arn}"
    },
    {
      "Effect": "Allow",
      "Action": "codestar-connections:UseConnection",
      "Resource": "${var.code_star_connection_arn}"
    }
  ]
}
EOF
}

################################################################################
# CodeBuild - General Step Role
################################################################################

resource "aws_iam_role" "codebuild_step_role" {
  name               = "${local.pipeline_name}-codebuild-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codebuild_step_policy" {
  #checkov:skip=CKV_AWS_290:Permissions for CodeBuild to create reports.
  #checkov:skip=CKV_AWS_355:Permissions for CodeBuild to create reports.
  name = "codebuild_policy"
  role = aws_iam_role.codebuild_step_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObject"
      ],
      "Resource": [
        "${var.artifacts_bucket_arn}",
        "${var.artifacts_bucket_arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:/aws/codebuild/${var.repository_name}*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:DescribeKey",
        "kms:GenerateDataKey*",
        "kms:Encrypt",
        "kms:ReEncrypt*",
        "kms:Decrypt"
      ],
      "Resource": "${var.artifacts_bucket_encryption_key_arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:CreateReportGroup",
        "codebuild:CreateReport",
        "codebuild:UpdateReport",
        "codebuild:BatchPutTestCases",
        "codebuild:BatchPutCodeCoverages"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "codestar-connections:UseConnection",
      "Resource": "${var.code_star_connection_arn}"
    },
    {
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "arn:aws:secretsmanager:${var.aws_region}:${var.account_id}:secret:${var.dockerhub_secret_name}*"
    }
  ]
}
EOF
}

################################################################################
# CodeBuild - Publish to ECR Role
################################################################################

resource "aws_iam_role" "publish_to_ecr_role" {
  name               = "${local.pipeline_name}-publish-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ecr_publish_policy" {
  #checkov:skip=CKV_AWS_290:Permissions for CodeBuild to create reports.
  #checkov:skip=CKV_AWS_355:Permissions for CodeBuild to create reports.
  name = "codebuild_policy"
  role = aws_iam_role.publish_to_ecr_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObject"
      ],
      "Resource": [
        "${var.artifacts_bucket_arn}",
        "${var.artifacts_bucket_arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:/aws/codebuild/${var.repository_name}*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:DescribeKey",
        "kms:GenerateDataKey*",
        "kms:Encrypt",
        "kms:ReEncrypt*",
        "kms:Decrypt"
      ],
      "Resource": "${var.artifacts_bucket_encryption_key_arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:CreateReportGroup",
        "codebuild:CreateReport",
        "codebuild:UpdateReport",
        "codebuild:BatchPutTestCases",
        "codebuild:BatchPutCodeCoverages"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchDeleteImage",
        "ecr:CompleteLayerUpload",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart"
      ],
      "Resource": [
          "arn:aws:ecr:${var.aws_region}:${var.account_id}:repository/${var.ecr_repository_name}"
      ]     
    },
    {
      "Effect": "Allow",
      "Action": "codestar-connections:UseConnection",
      "Resource": "${var.code_star_connection_arn}"
    }
  ]
}
EOF
}

################################################################################
# CodePipeline pipeline definition
################################################################################

resource "aws_codepipeline" "pipeline" {
  name       = local.pipeline_name
  role_arn   = aws_iam_role.codepipeline_role.arn
  depends_on = [aws_iam_role_policy.codepipeline_policy]

  artifact_store {
    location = var.pipeline_articats_bucket_name
    type     = "S3"

    encryption_key {
      id   = var.artifacts_bucket_encryption_key_arn
      type = "KMS"
    }
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        ConnectionArn        = var.code_star_connection_arn
        FullRepositoryId     = "${var.organization_name}/${var.repository_name}"
        BranchName           = var.branch_name
        OutputArtifactFormat = "CODEBUILD_CLONE_REF"
      }
    }
  }

  stage {
    name = "Security"

    action {
      name            = "SafetyScan"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.safety.name
      }
    }

    action {
      name            = "BanditScan"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.bandit.name
      }
    }

    action {
      name            = "GitSecrets"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.git_secrets.name
      }
    }

    action {
      name            = "TrivyScan"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.trivy.name
      }
    }

  }
  stage {
    name = "CodeValidation"
    action {
      name            = "Linter"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.pylint.name
      }
    }

    action {
      name            = "UnitTesting"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.pytest.name
      }
    }
  }
  stage {
    name = "Build"
    action {
      name             = "PushToEcr"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.ecr_push.name
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "ECSDeployment"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ClusterName = var.cluster_name
        ServiceName = var.service_name
      }
    }
  }

}

################################################################################
# CodePipeline  - Safety Step
################################################################################

resource "aws_codebuild_project" "safety" {
  #checkov:skip=CKV_AWS_316:Privileged Mode is required for using container runtime.
  #checkov:skip=CKV_AWS_314:Default Logging.
  name           = "${local.pipeline_name}-packages-audit"
  description    = "${var.repository_name} packages audit"
  service_role   = aws_iam_role.codebuild_step_role.arn
  build_timeout  = "15"
  encryption_key = var.artifacts_bucket_encryption_key_arn

  source {
    type      = "CODEPIPELINE"
    buildspec = <<EOF
version: 0.2
phases:
  pre_build:
    commands:
      - docker login --username $DOCKER_USERNAME --password $DOCKER_PASSWORD
  build:
    steps:
      - name: Main requirements vulnerabilities scan
        uses: aufdenpunkt/python-safety-check@master
        with:
          scan_requirements_file_only: 'true'
        env:
          DEP_PATH: "requirements.txt"
      - name: Dev requirements vulnerabilities scan
        uses: aufdenpunkt/python-safety-check@master
        with:
          scan_requirements_file_only: 'true'
        env:
          DEP_PATH: "requirements-dev.txt"
EOF
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = var.build_compute_type
    image           = var.build_image
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "DOCKER_USERNAME"
      value = "${var.dockerhub_secret_name}:username"
      type  = "SECRETS_MANAGER"
    }

    environment_variable {
      name  = "DOCKER_PASSWORD"
      value = "${var.dockerhub_secret_name}:password"
      type  = "SECRETS_MANAGER"
    }
  }
}

################################################################################
# CodePipeline  - Bandit Step
################################################################################

resource "aws_codebuild_project" "bandit" {
  #checkov:skip=CKV_AWS_316:Privileged Mode is required for using container runtime.
  #checkov:skip=CKV_AWS_314:Default Logging.
  name           = "${local.pipeline_name}-bandit"
  description    = "${var.repository_name} Bandit Scan"
  service_role   = aws_iam_role.codebuild_step_role.arn
  build_timeout  = "15"
  encryption_key = var.artifacts_bucket_encryption_key_arn

  source {
    type      = "CODEPIPELINE"
    buildspec = <<EOF
version: 0.2
phases:
  pre_build:
    commands:
      - docker login --username $DOCKER_USERNAME --password $DOCKER_PASSWORD
  build:
    steps:
      - uses: jpetrucciani/bandit-check@main
EOF
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = var.build_compute_type
    image           = var.build_image
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "DOCKER_USERNAME"
      value = "${var.dockerhub_secret_name}:username"
      type  = "SECRETS_MANAGER"
    }

    environment_variable {
      name  = "DOCKER_PASSWORD"
      value = "${var.dockerhub_secret_name}:password"
      type  = "SECRETS_MANAGER"
    }
  }
}

################################################################################
# CodePipeline  - Git-secrets Step
################################################################################

resource "aws_codebuild_project" "git_secrets" {
  #checkov:skip=CKV_AWS_316:Privileged Mode is required for using container runtime.
  #checkov:skip=CKV_AWS_314:Default Logging.
  name           = "${local.pipeline_name}-git-secrets"
  description    = "${var.repository_name} git-secrets Scan"
  service_role   = aws_iam_role.codebuild_step_role.arn
  build_timeout  = "15"
  encryption_key = var.artifacts_bucket_encryption_key_arn

  source {
    type      = "CODEPIPELINE"
    buildspec = <<EOF
version: 0.2
phases:
  install:
    commands:
      - SECRETS_FOLDER=git-secrets
      - mkdir $SECRETS_FOLDER
      - git clone --quiet https://github.com/awslabs/git-secrets.git $SECRETS_FOLDER
      - cd $SECRETS_FOLDER
      - make install
      - cd .. && rm -rf $SECRETS_FOLDER
  build:
    steps:
      - name: git-secrets scan
        run: |
          git secrets --register-aws
          git secrets --scan
          echo "No vulnerabilites detected. Have a nice day!"
EOF
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = var.build_compute_type
    image           = var.build_image
    type            = "LINUX_CONTAINER"
    privileged_mode = true
  }
}

################################################################################
# CodePipeline  - Trivy Step
################################################################################

resource "aws_codebuild_project" "trivy" {
  #checkov:skip=CKV_AWS_316:Privileged Mode is required for using container runtime.
  #checkov:skip=CKV_AWS_314:Default Logging.
  name           = "${local.pipeline_name}-trivy"
  description    = "${var.repository_name} Trivy Scan"
  service_role   = aws_iam_role.codebuild_step_role.arn
  build_timeout  = "15"
  encryption_key = var.artifacts_bucket_encryption_key_arn

  source {
    type      = "CODEPIPELINE"
    buildspec = <<EOF
version: 0.2
phases:
  build:
    steps:
      - name: Build local image
        run: |
          docker build -t app:local .
      - name: Run Trivy Scan
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: app:local
          format: 'table'
EOF
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = var.build_compute_type
    image           = var.build_image
    type            = "LINUX_CONTAINER"
    privileged_mode = true
  }
}

################################################################################
# CodePipeline  - PyLint Step
################################################################################

resource "aws_codebuild_project" "pylint" {
  #checkov:skip=CKV_AWS_316:Privileged Mode is required for using container runtime.
  #checkov:skip=CKV_AWS_314:Default Logging.
  name           = "${local.pipeline_name}-linter"
  description    = "${var.repository_name} PyLint"
  service_role   = aws_iam_role.codebuild_step_role.arn
  build_timeout  = "15"
  encryption_key = var.artifacts_bucket_encryption_key_arn

  source {
    type      = "CODEPIPELINE"
    buildspec = <<EOF
version: 0.2
phases:
  install:
    commands:
      - pip3 install -r requirements.txt
      - pip3 install -r requirements-dev.txt
  build:
    steps:
      - name: PyLint
        run: |
          find . -name '*.py' | xargs pylint
EOF
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = var.build_compute_type
    image           = var.build_image
    type            = "LINUX_CONTAINER"
    privileged_mode = true
  }
}

################################################################################
# CodePipeline  - PyTest Step
################################################################################

resource "aws_codebuild_project" "pytest" {
  #checkov:skip=CKV_AWS_314:Default Logging.
  name           = "${local.pipeline_name}-unit-tests"
  description    = "${var.repository_name} PyTest"
  service_role   = aws_iam_role.codebuild_step_role.arn
  build_timeout  = "15"
  encryption_key = var.artifacts_bucket_encryption_key_arn

  source {
    type      = "CODEPIPELINE"
    buildspec = <<EOF
version: 0.2
phases:
  install:
    commands:
      - pip3 install -r requirements.txt
      - pip3 install -r requirements-dev.txt
  build:
    steps:
      - name: Run Unit Tests with coverage
        run: |
          coverage erase && python3 -m coverage run --branch -m pytest -v && coverage report
          python3 -m coverage xml -i -o test-results/coverage.xml
          python3 -m pytest --junitxml=test-results/results.xml
reports:
  unit_tests_reports:
    files: results.xml
    base-directory: test-results
    file-format: JUNITXML
  coverage_reports:
    files: coverage.xml
    base-directory: test-results
    file-format: COBERTURAXML
EOF
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = var.build_compute_type
    image        = var.build_image
    type         = "LINUX_CONTAINER"
  }
}

################################################################################
# CodePipeline  - Build Step
################################################################################

resource "aws_codebuild_project" "ecr_push" {
  #checkov:skip=CKV_AWS_314:Default Logging.
  #checkov:skip=CKV_AWS_316:Privileged Mode is required for using container runtime.
  name           = "${local.pipeline_name}-build"
  description    = "${var.repository_name} Docker push"
  service_role   = aws_iam_role.publish_to_ecr_role.arn
  build_timeout  = "15"
  encryption_key = var.artifacts_bucket_encryption_key_arn

  source {
    type      = "CODEPIPELINE"
    buildspec = <<EOF
version: 0.2
phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - ACCOUNT=$(aws sts get-caller-identity | jq -r '.Account')
      - ECR_URL=$ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com
      - aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URL
      - IMAGE_TAG=$(cat version.txt)
      - URI=$ECR_URL/$ECR_REPO_NAME:$IMAGE_TAG
  build:
    steps:
      - name: Build docker image 
        run: |
          echo Building the Docker image...
          docker build -t local:latest $FOLDER_PATH
      - name: Tag and push image
        run: |
          echo Pushing the Docker image...
          docker tag local:latest $URI
          docker push $URI
      - name: Create ECS config files
        run: |
          mkdir artifacts
          printf '[{"name":"%s","imageUri":"%s"}]' "$CONTAINER_NAME" "$URI" > artifacts/imagedefinitions.json
          cat artifacts/imagedefinitions.json
artifacts:
  files:
    - '**/*'
  base-directory: 'artifacts'
  discard-paths: yes
EOF
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = var.build_compute_type
    image           = var.build_image
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "ECR_REPO_NAME"
      value = var.ecr_repository_name
    }
    environment_variable {
      name  = "FOLDER_PATH"
      value = "."
    }

    environment_variable {
      name  = "CONTAINER_NAME"
      value = var.container_name
    }
  }
}