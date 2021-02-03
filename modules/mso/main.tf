terraform {
  required_providers {
    mso = {
      source = "CiscoDevNet/mso"
      version = "~> 0.1.5"
    }
    # vault = {
    #   source = "hashicorp/vault"
    #   version = "2.18.0"
    # }
  }
}
#
#
# ### Vault Provider ###
# ## Username & Password provided by Workspace Variable
# variable vault_username {}
# variable vault_password {
#   sensitive = true
# }
#
# provider "vault" {
#   address = "https://Hashi-Vault-1F899TQ4290I3-1824033843.ap-southeast-2.elb.amazonaws.com"
#   skip_tls_verify = true
#   auth_login {
#     path = "auth/userpass/login/${var.vault_username}"
#     parameters = {
#       password = var.vault_password
#     }
#   }
# }
#
# data "vault_generic_secret" "aws-mso" {
#   path = "kv/aws-mso"
# }
#
### ACI Provider
# provider "mso" {
#   username = data.vault_generic_secret.aws-mso.data["username"]
#   password = data.vault_generic_secret.aws-mso.data["password"]
#   url      = "https://aws-syd-ase-n1.mel.ciscolabs.com/mso/"
#   insecure = true
# }
#
### Workaround Destory Variable

# variable "removeSites" {
#   default = true
# }

### Shared Data Sources ###
data "mso_tenant" "Production" {
  name = "Production"
  display_name = "Production"
}

data "mso_site" "AWS-SYD" {
  name  = "AWS-SYD"
}

data "mso_site" "AZURE-MEL" {
  name  = "AZURE-MEL"
}

# output "AWS-SYD-ID" {
#   value = data.mso_site.AWS-SYD.id
# }
#
# output "AZURE-MEL-ID" {
#   value = data.mso_site.AZURE-MEL.id
# }

### New Demo Schema & 1st Template ###
resource "mso_schema" "tf-hybrid-cloud" {
  name          = "tf-hybrid-cloud"
  template_name = "tf-hc-prod"
  tenant_id     = data.mso_tenant.Production.id
}

resource "mso_schema_template_vrf" "tf-hc-prod" {
  schema_id       = mso_schema.tf-hybrid-cloud.id
  template        = mso_schema.tf-hybrid-cloud.template_name
  name            = "tf-hc-prod"
  display_name    = "Terraform Hybrid Cloud Production"
  # layer3_multicast= false
  # vzany           = false
}

### Templates to Site ###

/*
PROVDER BROKEN - Can't add site to template, vrf needs region, not set, shouldn't need to be set either...
*/

# resource "mso_schema_site" "AWS-SYD" {
#   schema_id  = mso_schema.tf-hybrid-cloud.id
#   site_id  = data.mso_site.AWS-SYD.id
#   template_name  = mso_schema.tf-hybrid-cloud.template_name
# }

# resource "mso_schema_site" "AZURE-MEL" {
#   schema_id  = mso_schema.tf-hybrid-cloud.id
#   site_id  = data.mso_site.AZURE-MEL.id
#   template_name  = mso_schema.tf-hybrid-cloud.template_name
# }


# data "mso_schema_site" "AWS-SYD" {
#   name       = "AWS-SYD"
#   schema_id  = mso_schema.tf-hybrid-cloud.id
# }

# data "mso_schema_site" "AZURE-MEL" {
#   name       = "AZURE-MEL"
#   schema_id  = mso_schema.tf-hybrid-cloud.id
# }

### New Demo VRF - Extended Between Clouds ###
# resource "mso_schema_site_vrf" "tf-hc-prod-aws" {
#   template_name = mso_schema.tf-hybrid-cloud.template_name
#   site_id       = data.mso_schema_site.AWS-SYD.id
#   schema_id     = mso_schema.tf-hybrid-cloud.id
#   vrf_name      = mso_schema_template_vrf.tf-hc-prod.name
# }

# resource "mso_schema_site_vrf" "tf-hc-prod-azure" {
#   template_name = mso_schema.tf-hybrid-cloud.template_name
#   site_id       = data.mso_site.AZURE-MEL.id
#   schema_id     = mso_schema.tf-hybrid-cloud.id
#   vrf_name      = mso_schema_template_vrf.tf-hc-prod.name
# }

# resource "mso_schema_site_vrf_region" "tf-hc-prod-aws-syd" {
#   schema_id           = mso_schema.tf-hybrid-cloud.id
#   template_name       = mso_schema.tf-hybrid-cloud.template_name
#   site_id             = data.mso_site.AWS-SYD.id
#   vrf_name            = mso_schema_template_vrf.tf-hc-prod.name
#   region_name         = "ap-southeast-2"
#   vpn_gateway         = true
#   hub_network_enable  = true
#   hub_network = {
#     name        = "HUB1"
#     tenant_name = "infra"
#   }
#   # cidr {
#     cidr_ip = "10.11.0.0/16"
#     primary = true
#     subnet {
#       ip    = "10.11.1.1/24"
#       zone  = "ap-southeast-2a"
#       usage = "Primary"
#     }
#   }
# }

## Works after VRF defined manually

# resource "mso_schema_site_vrf_region_cidr_subnet" "tf-hc-prod-aws-syd-2" {
#   schema_id     = mso_schema.tf-hybrid-cloud.id
#   template_name = mso_schema.tf-hybrid-cloud.template_name
#   site_id       = data.mso_site.AWS-SYD.id
#   vrf_name      = "tf-hc-prod"
#   region_name   = "ap-southeast-2"
#   cidr_ip       = "10.11.0.0/16"
#   ip            = "10.11.2.1/24"
#   zone          = "ap-southeast-2b"
#   # usage         = "gateway"
# }

# resource "mso_schema_site_vrf_region" "tf-hc-prod-azure-mel" {
#   schema_id           = mso_schema.tf-hybrid-cloud.id
#   template_name       = mso_schema.tf-hybrid-cloud.template_name
#   site_id             = data.mso_site.AZURE-MEL.id
#   vrf_name            = mso_schema_site_vrf.tf-hc-prod-azure.vrf_name
#   region_name         = "australiasoutheast"
#   vpn_gateway         = false
#   cidr {
#     cidr_ip = "10.12.0.0/16"
#     primary = true
#     subnet {
#       ip    = "10.12.1.1/24"
#       zone  = "australiasoutheast"
#     }
#   }
# }

/*
resource "mso_rest" "aws_site" {
  path = "api/v1/schemas/${data.mso_schema.hybrid_cloud.id}"
  method = "PATCH"
  payload = <<EOF
[
  {
    "op": "add",
    "path": "/sites/-",
    "value": {
      "siteId": "${data.mso_site.aws.id}",
      "templateName": "Template1",
      "contracts": [
        {
          "contractRef": {
            "schemaId": "${data.mso_schema.hybrid_cloud.id}",
            "templateName": "Template1",
            "contractName": "${var.name_prefix}Internet-to-Web"
          }
        },{
          "contractRef": {
            "schemaId": "${data.mso_schema.hybrid_cloud.id}",
            "templateName": "Template1",
            "contractName": "${var.name_prefix}Web-to-DB"
          }
        },{
          "contractRef": {
            "schemaId": "${data.mso_schema.hybrid_cloud.id}",
            "templateName": "Template1",
            "contractName": "${var.name_prefix}VMs-to-Internet"
          }
        }
      ],
      "vrfs": [{
        "vrfRef": {
          "schemaId": "${data.mso_schema.hybrid_cloud.id}",
          "templateName": "Template1",
          "vrfName": "${var.name_prefix}Hybrid_Cloud_VRF"
        },
        "regions": [{
          "name": "us-west-1",
          "cidrs": [{
            "ip": "10.101.110.0/24",
            "primary": true,
            "subnets": [{
              "ip": "10.101.110.0/25",
              "zone": "us-west-1a",
              "name": "",
              "usage": "gateway"
            }, {
              "ip": "10.101.110.128/25",
              "zone": "us-west-1b",
              "name": "",
              "usage": "gateway"
            }],
            "associatedRegion": "us-west-1"
          }],
          "isVpnGatewayRouter": false,
          "isTGWAttachment": true,
          "cloudRsCtxProfileToGatewayRouterP": {
            "name": "default",
            "tenantName": "infra"
          },
          "hubnetworkPeering": false
        }]
      }],
      "intersiteL3outs": null
    }
  }
]
EOF

}
*/

# variable "aws_add" {
#   default = <<EOF
# [
#   {
#     "op": "add",
#     "path": "/sites/-",
#     "value": {
#       "siteId": "5ee1d66d0e00002c028f69f6",
#       "templateName": "tf-hc-prod",
#       "vrfs": [{
#         "vrfRef": {
#           "schemaId": "60120ac4350000e401453f8e",
#           "templateName": "tf-hc-prod",
#           "vrfName": "tf-hc-prod"
#         },
#         "regions": [{
#           "name": "ap-southeast-2",
#           "cidrs": [{
#             "ip": "10.11.0.0/16",
#             "primary": true,
#             "subnets": [
#               {
#               "ip": "10.11.1.0/24",
#               "zone": "ap-southeast-2a",
#               "name": "",
#               "usage": "gateway"
#               },
#               {
#               "ip": "10.11.2.0/24",
#               "zone": "ap-southeast-2b",
#               "name": "",
#               "usage": "gateway"
#               },
#               {
#               "ip": "10.11.3.0/24",
#               "zone": "ap-southeast-2a",
#               "name": ""
#               },
#               {
#               "ip": "10.11.4.0/24",
#               "zone": "ap-southeast-2b",
#               "name": ""
#               }
#             ],
#             "associatedRegion": "ap-southeast-2"
#           }],
#           "isVpnGatewayRouter": false,
#           "isTGWAttachment": true,
#           "cloudRsCtxProfileToGatewayRouterP": {
#             "name": "default",
#             "tenantName": "infra"
#           },
#           "hubnetworkPeering": false
#         }]
#       }],
#       "intersiteL3outs": null
#     }
#   }
# ]
# EOF
# }
#
# variable "aws_remove" {
#   default = <<EOF
# [
#   {
#     "op": "remove",
#     "path": "/sites/5ee1d66d0e00002c028f69f6",
#   }
# ]
# EOF
# }
#
# resource "mso_rest" "aws_site" {
#
#   # lifecycle {
#   #     create_before_destroy = true
#   #   }
#
#   # count = var.removeSites == true ? 1 : 0
#
#   path = "api/v1/schemas/${mso_schema.tf-hybrid-cloud.id}"
#   method = "PATCH"
#   payload = var.removeSites !=true ? var.aws_remove : var.aws_add
# }
#
# output "removeSites" {
#   value = var.removeSites
# }

# resource "mso_rest" "aws_site_remove" {
#   count = var.removeSites == true ? 0 : 1
#
#   path = "api/v1/schemas/${mso_schema.tf-hybrid-cloud.id}"
#   method = "PATCH"
#   payload = <<EOF
# [
#   {
#     "op": "remove",
#     "path": "/sites/${data.mso_site.AWS-SYD.id}",
#   }
# ]
# EOF
#
# }

resource "mso_rest" "vrf-workaround" {
    path = "api/v1/schemas/${mso_schema.tf-hybrid-cloud.id}"
    method = "PATCH"
    payload = <<EOF
[
  {
    "op": "add",
    "path": "/sites/-",
    "value": {
      "siteId": "${data.mso_site.AWS-SYD.id}",
      "templateName": "${mso_schema.tf-hybrid-cloud.template_name}",
      "vrfs": [{
        "vrfRef": {
          "schemaId": "${mso_schema.tf-hybrid-cloud.id}",
          "templateName": "${mso_schema.tf-hybrid-cloud.template_name}",
          "vrfName": "${mso_schema_template_vrf.tf-hc-prod.name}"
        },
        "regions": [{
          "name": "ap-southeast-2",
          "cidrs": [{
            "ip": "10.111.0.0/16",
            "primary": true,
            "subnets": [
              {
              "ip": "10.111.1.0/24",
              "zone": "ap-southeast-2a",
              "name": "",
              "usage": "gateway"
              },
              {
              "ip": "10.111.2.0/24",
              "zone": "ap-southeast-2b",
              "name": "",
              "usage": "gateway"
              },
              {
              "ip": "10.111.3.0/24",
              "zone": "ap-southeast-2a",
              "name": ""
              },
              {
              "ip": "10.111.4.0/24",
              "zone": "ap-southeast-2b",
              "name": ""
              }
            ],
            "associatedRegion": "ap-southeast-2"
          }],
          "isVpnGatewayRouter": false,
          "isTGWAttachment": true,
          "cloudRsCtxProfileToGatewayRouterP": {
            "name": "HUB1",
            "tenantName": "infra"
          },
          "hubnetworkPeering": false
        }]
      }],
      "intersiteL3outs": null
    }
  }
]
EOF

}

### Load VRF as Data ###
data "mso_schema_site_vrf" "tf-hc-prod-aws" {
  site_id   = data.mso_site.AWS-SYD.id
  schema_id = mso_schema.tf-hybrid-cloud.id
  vrf_name  = mso_schema_template_vrf.tf-hc-prod.name

  depends_on = [mso_rest.vrf-workaround]
}

data "mso_schema_site_vrf_region" "tf-hc-prod-aws-syd" {
  schema_id     = mso_schema.tf-hybrid-cloud.id
  site_id       = data.mso_site.AWS-SYD.id
  vrf_name      = mso_schema_template_vrf.tf-hc-prod.name
  region_name   = "ap-southeast-2"

  depends_on = [mso_rest.vrf-workaround]
}


### Application Network Profile ###
resource "mso_schema_template_anp" "tf-demo-app-1" {
  schema_id     = mso_schema.tf-hybrid-cloud.id
  template      = mso_schema.tf-hybrid-cloud.template_name
  name          = "tf-demo-app-1"
  display_name  = "Terraform Demo App 1"
}

resource "mso_schema_template_anp" "tf-k8s-1" {
  schema_id     = mso_schema.tf-hybrid-cloud.id
  template      = mso_schema.tf-hybrid-cloud.template_name
  name          = "tf-k8s-1"
  display_name  = "Terraform K8S Demo 1"
}

### ExEPGs

## Doesn't work until VRF configured per Site

resource "mso_schema_template_external_epg" "tf-public" {
  schema_id           = mso_schema.tf-hybrid-cloud.id
  template_name       = mso_schema.tf-hybrid-cloud.template_name
  external_epg_name   = "tf-public"
  external_epg_type   = "cloud"
  display_name        = "Public Internet"
  vrf_name            = mso_schema_template_vrf.tf-hc-prod.name
  anp_name            = mso_schema_template_anp.tf-demo-app-1.name
  # l3out_name          = "temp"
  site_id             = [data.mso_site.AWS-SYD.id]
  selector_name       = "tf-inet"
  selector_ip         = "0.0.0.0/0"

  depends_on = [
    mso_rest.vrf-workaround
  ]
}

### Ex EPGs to Contracts ###

## K8S
resource "mso_schema_template_external_epg_contract" "tf-public-4" {
  schema_id         = mso_schema.tf-hybrid-cloud.id
  template_name     = mso_schema.tf-hybrid-cloud.template_name
  contract_name     = mso_schema_template_contract.tf-inet-to-k8s.contract_name
  external_epg_name = mso_schema_template_external_epg.tf-public.external_epg_name
  relationship_type = "consumer"
}

## WordPress
resource "mso_schema_template_external_epg_contract" "tf-public-1" {
  schema_id         = mso_schema.tf-hybrid-cloud.id
  template_name     = mso_schema.tf-hybrid-cloud.template_name
  contract_name     = mso_schema_template_contract.tf-inet-to-wordpress.contract_name
  external_epg_name = mso_schema_template_external_epg.tf-public.external_epg_name
  relationship_type = "consumer"
}

resource "mso_schema_template_external_epg_contract" "tf-public-2" {
  schema_id         = mso_schema.tf-hybrid-cloud.id
  template_name     = mso_schema.tf-hybrid-cloud.template_name
  contract_name     = mso_schema_template_contract.tf-inet-to-mariadb.contract_name
  external_epg_name = mso_schema_template_external_epg.tf-public.external_epg_name
  relationship_type = "consumer"
}

resource "mso_schema_template_external_epg_contract" "tf-public-3" {
  schema_id         = mso_schema.tf-hybrid-cloud.id
  template_name     = mso_schema.tf-hybrid-cloud.template_name
  contract_name     = mso_schema_template_contract.tf-servers-to-inet.contract_name
  external_epg_name = mso_schema_template_external_epg.tf-public.external_epg_name
  relationship_type = "provider"
}

### App EPGs

## K8S
resource "mso_schema_template_anp_epg" "tf-k8s-worker" {
  schema_id                   = mso_schema.tf-hybrid-cloud.id
  template_name               = mso_schema.tf-hybrid-cloud.template_name
  anp_name                    = mso_schema_template_anp.tf-k8s-1.name
  name                        = "tf-k8s-worker"
  bd_name                     = "unspecified"
  vrf_name                    = mso_schema_template_vrf.tf-hc-prod.name
  display_name                = "K8S Worker Node"
}

resource "mso_schema_template_anp_epg_selector" "tf-wordpress" {
  schema_id     = mso_schema.tf-hybrid-cloud.id
  template_name = mso_schema.tf-hybrid-cloud.template_name
  anp_name      = mso_schema_template_anp.tf-k8s-1.name
  epg_name      = mso_schema_template_anp_epg.tf-k8s-worker.name
  name          = "tf-k8s-worker"
  expressions {
    key         = "Custom:EPG"
    operator    = "equals"
    value       = "tf-k8s-worker"
  }
}
## WordPress
resource "mso_schema_template_anp_epg" "tf-wordpress" {
  schema_id                   = mso_schema.tf-hybrid-cloud.id
  template_name               = mso_schema.tf-hybrid-cloud.template_name
  anp_name                    = mso_schema_template_anp.tf-demo-app-1.name
  name                        = "tf-wordpress"
  bd_name                     = "unspecified"
  vrf_name                    = mso_schema_template_vrf.tf-hc-prod.name
  display_name                = "WordPress"
}

resource "mso_schema_template_anp_epg_selector" "tf-wordpress" {
  schema_id     = mso_schema.tf-hybrid-cloud.id
  template_name = mso_schema.tf-hybrid-cloud.template_name
  anp_name      = mso_schema_template_anp.tf-demo-app-1.name
  epg_name      = mso_schema_template_anp_epg.tf-wordpress.name
  name          = "tf-wordpress"
  expressions {
    key         = "Custom:EPG"
    operator    = "equals"
    value       = "WordPress"
  }
}

resource "mso_schema_template_anp_epg" "tf-mariadb" {
  schema_id                   = mso_schema.tf-hybrid-cloud.id
  template_name               = mso_schema.tf-hybrid-cloud.template_name
  anp_name                    = mso_schema_template_anp.tf-demo-app-1.name
  name                        = "tf-mariadb"
  bd_name                     = "unspecified"
  vrf_name                    = mso_schema_template_vrf.tf-hc-prod.name
  display_name                = "MariaDB"
}

resource "mso_schema_template_anp_epg_selector" "tf-mariadb" {
  schema_id     = mso_schema.tf-hybrid-cloud.id
  template_name = mso_schema.tf-hybrid-cloud.template_name
  anp_name      = mso_schema_template_anp.tf-demo-app-1.name
  epg_name      = mso_schema_template_anp_epg.tf-mariadb.name
  name          = "tf-mariadb"
  expressions {
    key         = "Custom:EPG"
    operator    = "equals"
    value       = "MariaDB"
  }
}

### App EPG to Contracts ###
resource "mso_schema_template_anp_epg_contract" "tf-wordpress-1" {
  schema_id         = mso_schema.tf-hybrid-cloud.id
  template_name     = mso_schema.tf-hybrid-cloud.template_name
  anp_name          = mso_schema_template_anp.tf-demo-app-1.name
  epg_name          = mso_schema_template_anp_epg.tf-wordpress.name
  contract_name     = mso_schema_template_contract.tf-inet-to-wordpress.contract_name
  relationship_type = "provider"
}

resource "mso_schema_template_anp_epg_contract" "tf-wordpress-2" {
  schema_id         = mso_schema.tf-hybrid-cloud.id
  template_name     = mso_schema.tf-hybrid-cloud.template_name
  anp_name          = mso_schema_template_anp.tf-demo-app-1.name
  epg_name          = mso_schema_template_anp_epg.tf-wordpress.name
  contract_name     = mso_schema_template_contract.tf-wordpress-to-mariadb.contract_name
  relationship_type = "consumer"
}

resource "mso_schema_template_anp_epg_contract" "tf-wordpress-3" {
  schema_id         = mso_schema.tf-hybrid-cloud.id
  template_name     = mso_schema.tf-hybrid-cloud.template_name
  anp_name          = mso_schema_template_anp.tf-demo-app-1.name
  epg_name          = mso_schema_template_anp_epg.tf-wordpress.name
  contract_name     = mso_schema_template_contract.tf-servers-to-inet.contract_name
  relationship_type = "consumer"
}

resource "mso_schema_template_anp_epg_contract" "tf-mariadb-1" {
  schema_id         = mso_schema.tf-hybrid-cloud.id
  template_name     = mso_schema.tf-hybrid-cloud.template_name
  anp_name          = mso_schema_template_anp.tf-demo-app-1.name
  epg_name          = mso_schema_template_anp_epg.tf-mariadb.name
  contract_name     = mso_schema_template_contract.tf-inet-to-mariadb.contract_name
  relationship_type = "provider"
}

resource "mso_schema_template_anp_epg_contract" "tf-mariadb-2" {
  schema_id         = mso_schema.tf-hybrid-cloud.id
  template_name     = mso_schema.tf-hybrid-cloud.template_name
  anp_name          = mso_schema_template_anp.tf-demo-app-1.name
  epg_name          = mso_schema_template_anp_epg.tf-mariadb.name
  contract_name     = mso_schema_template_contract.tf-wordpress-to-mariadb.contract_name
  relationship_type = "provider"
}

resource "mso_schema_template_anp_epg_contract" "tf-mariadb-3" {
  schema_id         = mso_schema.tf-hybrid-cloud.id
  template_name     = mso_schema.tf-hybrid-cloud.template_name
  anp_name          = mso_schema_template_anp.tf-demo-app-1.name
  epg_name          = mso_schema_template_anp_epg.tf-mariadb.name
  contract_name     = mso_schema_template_contract.tf-servers-to-inet.contract_name
  relationship_type = "consumer"
}

## K8S
resource "mso_schema_template_anp_epg_contract" "tf-k8s-worker-1" {
  schema_id         = mso_schema.tf-hybrid-cloud.id
  template_name     = mso_schema.tf-hybrid-cloud.template_name
  anp_name          = mso_schema_template_anp.tf-k8s-1.name
  epg_name          = mso_schema_template_anp_epg.tf-k8s-worker.name
  contract_name     = mso_schema_template_contract.tf-servers-to-inet.contract_name
  relationship_type = "consumer"
}

resource "mso_schema_template_anp_epg_contract" "tf-k8s-worker-2" {
  schema_id         = mso_schema.tf-hybrid-cloud.id
  template_name     = mso_schema.tf-hybrid-cloud.template_name
  anp_name          = mso_schema_template_anp.tf-k8s-1.name
  epg_name          = mso_schema_template_anp_epg.tf-k8s-worker.name
  contract_name     = mso_schema_template_contract.tf-inet-to-k8s.contract_name
  relationship_type = "provider"
}

### Contracts ###

## k8s
resource "mso_schema_template_contract" "tf-inet-to-k8s" {
  schema_id               = mso_schema.tf-hybrid-cloud.id
  template_name           = mso_schema.tf-hybrid-cloud.template_name
  contract_name           = "tf-inet-to-k8s"
  display_name            = "Internet to K8S Workers"
  filter_type             = "bothWay"
  scope                   = "context"
  filter_relationships    = {
    filter_name           = mso_schema_template_filter_entry.tf-allow-icmp.name
  }
  directives = ["none"]
}

# resource "mso_schema_template_contract_filter" "tf-inet-to-k8s-2" {
#   schema_id       = mso_schema.tf-hybrid-cloud.id
#   template_name   = mso_schema.tf-hybrid-cloud.template_name
#   contract_name   = mso_schema_template_contract.tf-inet-to-k8s.contract_name
#   filter_type     = "bothWay"
#   filter_name     = mso_schema_template_filter_entry.tf-allow-ssh.name
#   directives      = ["none"]
# }

resource "mso_schema_template_contract_filter" "tf-inet-to-k8s-2" {
  schema_id       = mso_schema.tf-hybrid-cloud.id
  template_name   = mso_schema.tf-hybrid-cloud.template_name
  contract_name   = mso_schema_template_contract.tf-inet-to-k8s.contract_name
  filter_type     = "bothWay"
  filter_name     = mso_schema_template_filter_entry.tf-allow-http-1.name
  directives      = ["none"]
}


## WordPress
resource "mso_schema_template_contract" "tf-inet-to-wordpress" {
  schema_id               = mso_schema.tf-hybrid-cloud.id
  template_name           = mso_schema.tf-hybrid-cloud.template_name
  contract_name           = "tf-inet-to-wordpress"
  display_name            = "Internet to WordPress"
  filter_type             = "bothWay"
  scope                   = "context"
  filter_relationships    = {
    # filter_schema_id      = mso_schema.tf-hybrid-cloud.id
    # filter_template_name  = mso_schema_template.tf-hc-prod.name
    filter_name           = mso_schema_template_filter_entry.tf-allow-icmp.name
  }
  directives = ["none"]
}

resource "mso_schema_template_contract_filter" "tf-inet-to-wordpress-2" {
  schema_id       = mso_schema.tf-hybrid-cloud.id
  template_name   = mso_schema.tf-hybrid-cloud.template_name
  contract_name   = mso_schema_template_contract.tf-inet-to-wordpress.contract_name
  filter_type     = "bothWay"
  filter_name     = mso_schema_template_filter_entry.tf-allow-ssh.name
  directives      = ["none"]
}

resource "mso_schema_template_contract_filter" "tf-inet-to-wordpress-3" {
  schema_id       = mso_schema.tf-hybrid-cloud.id
  template_name   = mso_schema.tf-hybrid-cloud.template_name
  contract_name   = mso_schema_template_contract.tf-inet-to-wordpress.contract_name
  filter_type     = "bothWay"
  filter_name     = mso_schema_template_filter_entry.tf-allow-http-1.name
  directives      = ["none"]
}

resource "mso_schema_template_contract" "tf-inet-to-mariadb" {
  schema_id               = mso_schema.tf-hybrid-cloud.id
  template_name           = mso_schema.tf-hybrid-cloud.template_name
  contract_name           = "tf-inet-to-mariadb"
  display_name            = "Internet to MariaDB"
  filter_type             = "bothWay"
  scope                   = "context"
  filter_relationships    = {
    # filter_schema_id      = mso_schema.tf-hybrid-cloud.id
    # filter_template_name  = mso_schema_template.tf-hc-prod.name
    filter_name           = mso_schema_template_filter_entry.tf-allow-icmp.name
  }
  directives = ["none"]
}

resource "mso_schema_template_contract_filter" "tf-inet-to-mariadb-2" {
  schema_id       = mso_schema.tf-hybrid-cloud.id
  template_name   = mso_schema.tf-hybrid-cloud.template_name
  contract_name   = mso_schema_template_contract.tf-inet-to-mariadb.contract_name
  filter_type     = "bothWay"
  filter_name     = mso_schema_template_filter_entry.tf-allow-ssh.name
  directives      = ["none"]
}

resource "mso_schema_template_contract" "tf-servers-to-inet" {
  schema_id               = mso_schema.tf-hybrid-cloud.id
  template_name           = mso_schema.tf-hybrid-cloud.template_name
  contract_name           = "tf-servers-to-inet"
  display_name            = "Servers to Internet"
  filter_type             = "bothWay"
  scope                   = "context"
  filter_relationships    = {
    # filter_schema_id      = mso_schema.tf-hybrid-cloud.id
    # filter_template_name  = mso_schema_template.tf-hc-prod.name
    filter_name           = mso_schema_template_filter_entry.tf-allow-any.name
  }
  directives = ["none"]
}

resource "mso_schema_template_contract" "tf-wordpress-to-mariadb" {
  schema_id               = mso_schema.tf-hybrid-cloud.id
  template_name           = mso_schema.tf-hybrid-cloud.template_name
  contract_name           = "tf-wordpress-to-mariadb"
  display_name            = "WordPress to MariaDB"
  filter_type             = "bothWay"
  scope                   = "context"
  filter_relationships    = {
    # filter_schema_id      = mso_schema.tf-hybrid-cloud.id
    # filter_template_name  = mso_schema_template.tf-hc-prod.name
    filter_name           = mso_schema_template_filter_entry.tf-allow-icmp.name
  }
  directives = ["none"]
}

resource "mso_schema_template_contract_filter" "tf-wordpress-to-mariadb-2" {
  schema_id       = mso_schema.tf-hybrid-cloud.id
  template_name   = mso_schema.tf-hybrid-cloud.template_name
  contract_name   = mso_schema_template_contract.tf-wordpress-to-mariadb.contract_name
  filter_type     = "bothWay"
  filter_name     = mso_schema_template_filter_entry.tf-allow-mysql.name
  directives      = ["none"]
}


### Filter Entries ###
resource "mso_schema_template_filter_entry" "tf-allow-any" {
  schema_id             = mso_schema.tf-hybrid-cloud.id
  template_name         = mso_schema.tf-hybrid-cloud.template_name
  name                  = "tf-allow-any"
  display_name          = "Allow Any"
  entry_name            = "any"
  entry_display_name    = "ANY"
  entry_description     = "Any IP Source & Destination Port & Protocol"
  ether_type            = "ip"
  # ip_protocol = "unspecified"
  # destination_from = "unspecified"
  # destination_to = "unspecified"
  # source_from = "unspecified"
  # source_to = "unspecified"
}

resource "mso_schema_template_filter_entry" "tf-allow-http-1" {
  schema_id             = mso_schema.tf-hybrid-cloud.id
  template_name         = mso_schema.tf-hybrid-cloud.template_name
  name                  = "tf-allow-http"
  display_name          = "Allow HTTP"
  entry_name            = "http"
  entry_display_name    = "HTTP"
  entry_description     = "Allow Any to Destination HTTP TCP 80"
  ether_type            = "ip"
  ip_protocol           = "tcp"
  destination_from      = "http"
  destination_to        = "http"
}

resource "mso_schema_template_filter_entry" "tf-allow-http-2" {
  schema_id             = mso_schema.tf-hybrid-cloud.id
  template_name         = mso_schema.tf-hybrid-cloud.template_name
  name                  = "tf-allow-http"
  display_name          = "Allow HTTP"
  entry_name            = "https"
  entry_display_name    = "HTTPS"
  entry_description     = "Allow Any to Destination HTTPS TCP 443"
  ether_type            = "ip"
  ip_protocol           = "tcp"
  destination_from      = "https"
  destination_to        = "https"
}

resource "mso_schema_template_filter_entry" "tf-allow-icmp" {
  schema_id             = mso_schema.tf-hybrid-cloud.id
  template_name         = mso_schema.tf-hybrid-cloud.template_name
  name                  = "tf-allow-icmp"
  display_name          = "Allow ICMP"
  entry_name            = "icmp"
  entry_display_name    = "ICMP"
  entry_description     = "Any ICMP Protocol"
  ether_type            = "ip"
  ip_protocol           = "icmp"
  # destination_from = "unspecified"
  # destination_to = "unspecified"
  # source_from = "unspecified"
  # source_to = "unspecified"
}

resource "mso_schema_template_filter_entry" "tf-allow-mysql" {
  schema_id             = mso_schema.tf-hybrid-cloud.id
  template_name         = mso_schema.tf-hybrid-cloud.template_name
  name                  = "tf-allow-mysql"
  display_name          = "Allow MySQL"
  entry_name            = "mysql"
  entry_display_name    = "MySQL"
  entry_description     = "Allow Any to Destination MySQL TCP 3306"
  ether_type            = "ip"
  ip_protocol           = "tcp"
  destination_from      = "3306"
  destination_to        = "3306"
}

resource "mso_schema_template_filter_entry" "tf-allow-ssh" {
  schema_id             = mso_schema.tf-hybrid-cloud.id
  template_name         = mso_schema.tf-hybrid-cloud.template_name
  name                  = "tf-allow-ssh"
  display_name          = "Allow SSH"
  entry_name            = "ssh"
  entry_display_name    = "SSH"
  entry_description     = "Allow Any to Destination SSH TCP 22"
  ether_type            = "ip"
  ip_protocol           = "tcp"
  destination_from      = "ssh"
  destination_to        = "ssh"
}


### DEPLOY

resource "mso_schema_template_deploy" "aws_syd" {
  schema_id     = mso_schema.tf-hybrid-cloud.id
  template_name = mso_schema.tf-hybrid-cloud.template_name
  site_id       = data.mso_site.AWS-SYD.id
  undeploy      = false
}
