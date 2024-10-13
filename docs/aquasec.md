## Security Component - AquaSec Integration module

The sensitive information for AquaSec will be managed by AWS Secrets Manager.

- **aqua_url**: Should be the Aqua URL created by your account on AquaSec.
- **username**: Should be the Username created by your account on AquaSec.
- **password**: Should be the Password created by your account on AquaSec.

For more information about AquaSec please check the [official docs](https://registry.terraform.io/providers/aquasecurity/aquasec/latest/docs).

Go to **patterns/fargate-cluster/aquasec.tf.draft** and rename the file to **aquasec.tf**, after go to **patterns/fargate-cluster/terraform.tfvars** and configure the following parameters:

```shell
################################################################################
# Module - Aquasec
################################################################################

enable_aquasec                        = false  -------> true
enable_aquasec_sidecar                = false
enable_aquasec_sidecar_ecr_repository = false

aquasec = {
  secret_manager_name = "aquasec"
}

aquasec_microenforcer_sidecar = {
  name               = "aqua-sidecar"
  cpu                = 512
  memory             = 1024
  essential          = false
  image              = "xxxxxxxx.dkr.ecr.us-east-1.amazonaws.com/aqua-sidecar:latest"
  memory_reservation = 50
}

secret_aquasec = {
    aqua_url = "https://cloud.aquasec.com"
    username = "username"  -------> Your username
    password = "password"  -------> Your password
  }

```

### MicroEnforcer Sidecar (Vulnerabilities Scanning and Protection)

The MicroEnforcer is supplied as an executable which is embedded as a component of your container image.

#### Deploy Amazon ECR

Configure the following parameters on **patterns/fargate-cluster/terraform.tfvars**:

```shell
################################################################################
# Module - Aquasec
################################################################################

...

enable_aquasec_sidecar_ecr_repository = true

...

```

Deploy Aqua Sidecar ECR Repository:

```shell
terraform init
terraform validate
terraform plan #Here check the plan that Terraform outputs in case you want to change something.
terraform apply --auto-approve
```

#### Build container image for Aqua Sidecar

You can obtain MicroEnforcer using the link below. You will need the username and password you have received from Aqua Security.

```shell
https://download.aquasec.com/micro-enforcer/2022.4/x86/microenforcer
```

Alternatively, for the ARM64 executable:

```shell
https://download.aquasec.com/micro-enforcer/2022.4/arm64/microenforcer
```

Give the file execute permission:

```shell
chmod +x microenforcer
```

Copy the file on **patterns/aquasec-sidecar**.

Move to **patterns/aquasec-sidecar**, build and push the sidecar image to your registry:

```shell
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin xxxxxxx.dkr.ecr.us-east-1.amazonaws.com
```
```shell
docker build --no-cache -t aqua-sidecar . --platform linux/amd64
```
```shell
docker tag aqua-sidecar:latest xxxxxxx.dkr.ecr.us-east-1.amazonaws.com/aqua-sidecar:latest
```
```shell
docker push xxxxxxx.dkr.ecr.us-east-1.amazonaws.com/aqua-sidecar:latest
```

- **xxxxxxx** represents the aws account id.

#### Add Aqua Sidecar into your ECS Service 

In the section **ECS Service Sample** on **patterns/fargate-cluster/terraform.tfvars**, please uncomment the following lines:

```shell
################################################################################
# ECS Service Sample
################################################################################

...

# container_sample_entrypoint = ["/.aquasec/bin/microenforcer","bash", "/usr/src/app/startup.sh"]
# container_sample_command    = []
# container_sample_environment = [
#   {
#     name  = "AQUA_MICROENFORCER"
#     value = "1"
#   },
#   {
#     name  = "AQUA_SERVER"
#     value = "xxxxxxx-gw.cloud.aquasec.com:443"
#   },
#   {
#     name  = "AQUA_TOKEN"
#     value = "xxxxxx-xxxxx-xxxxx-xxxxx-xxxxx"
#   },
#   {
#     name  = "AQUA_IMAGE_ID"
#     value = "xxxxx"
#   }
# ]

# container_sample_volumes_from = [{
#   sourceContainer = "aqua-sidecar"
#   readOnly        = false
# }]
```

- **AQUA_MICROENFORCER**: Required to make runtime protection operate in MicroEnforcer mode.
- **AQUA_SERVER**: The IP address and port (usually 443) of any Aqua Gateway.
- **AQUA_TOKEN**: The deployment token of any MicroEnforcer group. In the Aqua UI: Navigate to Administration > Aqua Enforcers and edit a MicroEnforcer group (e.g., the "default micro enforcer group").
- **AQUA_IMAGE_ID**: The Docker image ID of the application image. Do not specify this if you want the MicroEnforcer to fetch the image name and image digest from ECS metadata (recommended).

**NOTE**: Since the sidecar container will run very briefly, to expose the MicroEnforcer executable.

Also, Configure the following parameters on **patterns/fargate-cluster/terraform.tfvars**:

```shell
################################################################################
# Module - Aquasec
################################################################################

...

enable_aquasec_sidecar = true

...

aquasec_microenforcer_sidecar = {
  name               = "aqua-sidecar"
  cpu                = 512
  memory             = 1024
  essential          = false
  image              = "xxxxxxxx.dkr.ecr.us-east-1.amazonaws.com/aqua-sidecar:latest"
  memory_reservation = 50
}

...

```

- **name**: Aqua Sidecar container name (no changes required).
- **cpu**: Aqua Sidecar container cpu (no changes required).
- **memory**: Aqua Sidecar container memory (no changes required).
- **essential**: Aqua Sidecar container essential (no changes required).
- **image**: Aqua Sidecar container image (change **xxxxxxxx** for your AWS Account).
- **memory_reservation**: Aqua Sidecar container memory reservation (no changes required).

Deploy Aqua Sidecar Integration:

```shell
terraform init
terraform validate
terraform plan #Here check the plan that Terraform outputs in case you want to change something.
terraform apply --auto-approve
```

### Cleanup

Rename **aquasec.tf** to **aquasec.tf.draft** and configure the following values:

```shell
################################################################################
# Module - Aquasec
################################################################################

enable_aquasec                        = true  -------> false

```


