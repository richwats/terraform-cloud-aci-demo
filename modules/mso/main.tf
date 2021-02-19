terraform {
  required_providers {
    mso = {
      source = "CiscoDevNet/mso"
      version = "~> 0.1.5"
    }
  }
}

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

## AWS VRF WORKAROUND
resource "mso_rest" "vrf-workaround-aws" {
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

## AZURE VRF WORKAROUND
resource "mso_rest" "vrf-workaround-azure" {
    path = "api/v1/schemas/${mso_schema.tf-hybrid-cloud.id}"
    method = "PATCH"
    payload = <<EOF
[
  {
    "op": "add",
    "path": "/sites/-",
    "value": {
      "siteId": "${data.mso_site.AZURE-MEL.id}",
      "templateName": "${mso_schema.tf-hybrid-cloud.template_name}",
      "vrfs": [{
        "vrfRef": {
          "schemaId": "${mso_schema.tf-hybrid-cloud.id}",
          "templateName": "${mso_schema.tf-hybrid-cloud.template_name}",
          "vrfName": "${mso_schema_template_vrf.tf-hc-prod.name}"
        },
        "regions": [{
          "name": "australiasoutheast",
          "cidrs": [{
            "ip": "10.112.0.0/16",
            "primary": true,
            "subnets": [
              {
              "ip": "10.112.1.0/24",
              "zone": "",
              "name": "",
              },
              {
              "ip": "10.112.2.0/24",
              "zone": "",
              "name": "",
              },
              {
              "ip": "10.111.3.0/24",
              "zone": "",
              "name": ""
              },
              {
              "ip": "10.111.4.0/24",
              "zone": "",
              "name": ""
              }
            ],
            "associatedRegion": "australiasoutheast"
          }],
          "isVpnGatewayRouter": false,
          "hubnetworkPeering": true
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


### Common ExEPGs

### ExEPG Needs ANP First...
resource "mso_schema_template_anp" "tf-shared" {
  schema_id           = mso_schema.tf-hybrid-cloud.id
  template            = mso_schema.tf-hybrid-cloud.template_name
  name                = "tf-shared"
  display_name        = "Terraform Shared Services"
}

## Doesn't work until VRF configured per Site
resource "mso_schema_template_external_epg" "tf-public" {
  schema_id           = mso_schema.tf-hybrid-cloud.id
  template_name       = mso_schema.tf-hybrid-cloud.template_name
  external_epg_name   = "tf-public"
  external_epg_type   = "cloud"
  display_name        = "Public Internet"
  vrf_name            = mso_schema_template_vrf.tf-hc-prod.name
  anp_name            = mso_schema_template_anp.tf-shared.name
  # l3out_name          = "temp"
  site_id             = [data.mso_site.AWS-SYD.id]
  selector_name       = "tf-inet"
  selector_ip         = "0.0.0.0/0"

  depends_on = [
    mso_rest.vrf-workaround
  ]
}

### Common Contracts
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

### Common Filter Entries ###
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

### Ex EPGs to Contracts ###
resource "mso_schema_template_external_epg_contract" "tf-public-1" {
  schema_id             = mso_schema.tf-hybrid-cloud.id
  template_name         = mso_schema.tf-hybrid-cloud.template_name
  contract_name         = mso_schema_template_contract.tf-servers-to-inet.contract_name
  external_epg_name     = mso_schema_template_external_epg.tf-public.external_epg_name
  relationship_type     = "provider"
}
