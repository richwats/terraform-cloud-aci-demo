terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "mel-ciscolabs-com"
    workspaces {
      name = "terraform-cloud-mso"
    }
  }
  required_providers {
    mso = {
      source = "CiscoDevNet/mso"
      version = "~> 0.1.5"
    }
    # aws = {
    #   source = "hashicorp/aws"
    #   version = "3.25.0"
    # }
    vault = {
      source = "hashicorp/vault"
      version = "2.18.0"
    }
  }
}


### Vault Provider ###
## Username & Password provided by Workspace Variable
variable vault_username {}
variable vault_password {
  sensitive = true
}

provider "vault" {
  address = "https://Hashi-Vault-1F899TQ4290I3-1824033843.ap-southeast-2.elb.amazonaws.com"
  skip_tls_verify = true
  auth_login {
    path = "auth/userpass/login/${var.vault_username}"
    parameters = {
      password = var.vault_password
    }
  }
}

### Cisco MSO Provider ###
data "vault_generic_secret" "aws-mso" {
  path = "kv/aws-mso"
}

provider "mso" {
  username = data.vault_generic_secret.aws-mso.data["username"]
  password = data.vault_generic_secret.aws-mso.data["password"]
  url      = "https://aws-syd-ase-n1.mel.ciscolabs.com/mso/"
  insecure = true
}

### AWS Provider ###
data "vault_generic_secret" "aws-prod" {
  path = "kv/aws-prod"
}

provider "aws" {
  region     = "ap-southeast-2"
  access_key = data.vault_generic_secret.aws-prod.data["access"]
  secret_key = data.vault_generic_secret.aws-prod.data["secret"]
}

### Nested Modules ###

## Common Setup - Schema, Template, VRFs etc
module "cloud-aci" {
  source = "./modules/mso"
}

module "app-k8s" {
  source = "./modules/apps/k8s"
  inputTest = module.cloud-aci.AWS_SYD
}

# module "app-wordpress" {
#   source = "./modules/apps/wordpress"
# }

# ### TRIGGER DEPLOY
#
# ## AWS
# resource "mso_schema_template_deploy" "aws_syd" {
#   schema_id     = module.cloud-aci.schema-prod.tf-hybrid-cloud.id
#   template_name = module.cloud-aci.schema-prod.tf-hybrid-cloud.template_name
#   site_id       = module.cloud-aci.AWS-SYD.id
#   undeploy      = false
# }
#
# output "test3" {
#   value = module.app-wordpress.test-schema
# }

# output "test1" {
#   value = module.cloud-aci.aws-syd-prod-vrf
# }
#
# output "test2" {
#   value = module.cloud-aci.aws-syd-reg
# }
