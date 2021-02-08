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

### Shared Schema & VRF Details
data "mso_schema" "tf-hybrid-cloud" {
  name          = "tf-hybrid-cloud"
}

### Common Production VRF
data "mso_schema_template_vrf" "tf-hc-prod"  {
  schema_id       = data.mso_schema.tf-hybrid-cloud.id
  template        = data.mso_schema.tf-hybrid-cloud.template_name
  name            = "tf-hc-prod"
}

## Load Common ExEPGs
data "mso_schema_template_external_epg" "tf-public" {
  schema_id           = data.mso_schema.tf-hybrid-cloud.id
  template_name       = data.mso_schema.tf-hybrid-cloud.template_name
  external_epg_name   = "tf-public"
}

## Load Common Contract
data "mso_schema_template_contract" "tf-servers-to-inet" {
  schema_id               = data.mso_schema.tf-hybrid-cloud.id
  template_name           = data.mso_schema.tf-hybrid-cloud.template_name
  contract_name           = "tf-servers-to-inet"
}

## Load Common Filters
data "mso_schema_template_filter_entry" "tf-allow-any" {
  schema_id             = data.mso_schema.tf-hybrid-cloud.id
  template_name         = data.mso_schema.tf-hybrid-cloud.template_name
  name                  = "tf-allow-any"
  entry_name            = "any"
}

data "mso_schema_template_filter_entry" "tf-allow-http" {
  schema_id             = data.mso_schema.tf-hybrid-cloud.id
  template_name         = data.mso_schema.tf-hybrid-cloud.template_name
  name                  = "tf-allow-http"
  entry_name            = "http"
}

data "mso_schema_template_filter_entry" "tf-allow-icmp" {
  schema_id             = data.mso_schema.tf-hybrid-cloud.id
  template_name         = data.mso_schema.tf-hybrid-cloud.template_name
  name                  = "tf-allow-icmp"
  entry_name            = "icmp"
}

data "mso_schema_template_filter_entry" "tf-allow-ssh" {
  schema_id             = data.mso_schema.tf-hybrid-cloud.id
  template_name         = data.mso_schema.tf-hybrid-cloud.template_name
  name                  = "tf-allow-ssh"
  entry_name            = "ssh"
}

data "mso_schema_template_filter_entry" "tf-allow-mysql" {
  schema_id             = data.mso_schema.tf-hybrid-cloud.id
  template_name         = data.mso_schema.tf-hybrid-cloud.template_name
  name                  = "tf-allow-mysql"
  entry_name            = "mysql"
}

### AWS Site Specific Data

## Load VRF as Data ###
data "mso_schema_site_vrf" "tf-hc-prod-aws" {
  site_id   = data.mso_site.AWS-SYD.id
  schema_id = data.mso_schema.tf-hybrid-cloud.id
  vrf_name  = data.mso_schema_template_vrf.tf-hc-prod.name
  # depends_on = [mso_rest.vrf-workaround]
}

data "mso_schema_site_vrf_region" "tf-hc-prod-aws-syd" {
  schema_id     = data.mso_schema.tf-hybrid-cloud.id
  site_id       = data.mso_site.AWS-SYD.id
  vrf_name      = data.mso_schema_template_vrf.tf-hc-prod.name
  region_name   = "ap-southeast-2"
  # depends_on = [mso_rest.vrf-workaround]
}


# ## Create New Subnets for K8S Applciation
# resource "mso_schema_site_vrf_region_cidr_subnet" "tf-hc-prod-aws-syd-1" {
#   schema_id     = data.mso_schema.tf-hybrid-cloud.id
#   template_name = data.mso_schema.tf-hybrid-cloud.template_name
#   site_id       = data.mso_site.AWS-SYD.id
#   vrf_name      = "tf-hc-prod"
#   region_name   = "ap-southeast-2"
#   cidr_ip       = "10.111.0.0/16"
#   ip            = "10.111.5.0/24"
#   zone          = "ap-southeast-2a"
#   usage         = "EKS"
# }
#
# resource "mso_schema_site_vrf_region_cidr_subnet" "tf-hc-prod-aws-syd-2" {
#   schema_id     = data.mso_schema.tf-hybrid-cloud.id
#   template_name = data.mso_schema.tf-hybrid-cloud.template_name
#   site_id       = data.mso_site.AWS-SYD.id
#   vrf_name      = "tf-hc-prod"
#   region_name   = "ap-southeast-2"
#   cidr_ip       = "10.111.0.0/16"
#   ip            = "10.111.6.0/24"
#   zone          = "ap-southeast-2b"
#   usage         = "EKS"
# }
#


### Application Network Profile ###
resource "mso_schema_template_anp" "tf-demo-app-1" {
  schema_id     = data.mso_schema.tf-hybrid-cloud.id
  template      = data.mso_schema.tf-hybrid-cloud.template_name
  name          = "tf-demo-app-1"
  display_name  = "Terraform Demo App 1"
}


### App EPGs
resource "mso_schema_template_anp_epg" "tf-wordpress" {
  schema_id                   = data.mso_schema.tf-hybrid-cloud.id
  template_name               = data.mso_schema.tf-hybrid-cloud.template_name
  anp_name                    = mso_schema_template_anp.tf-demo-app-1.name
  name                        = "tf-wordpress"
  bd_name                     = "unspecified"
  vrf_name                    = data.mso_schema_template_vrf.tf-hc-prod.name
  display_name                = "WordPress"
}

resource "mso_schema_template_anp_epg_selector" "tf-wordpress" {
  schema_id     = data.mso_schema.tf-hybrid-cloud.id
  template_name = data.mso_schema.tf-hybrid-cloud.template_name
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
  schema_id                   = data.mso_schema.tf-hybrid-cloud.id
  template_name               = data.mso_schema.tf-hybrid-cloud.template_name
  anp_name                    = mso_schema_template_anp.tf-demo-app-1.name
  name                        = "tf-mariadb"
  bd_name                     = "unspecified"
  vrf_name                    = data.mso_schema_template_vrf.tf-hc-prod.name
  display_name                = "MariaDB"
}

resource "mso_schema_template_anp_epg_selector" "tf-mariadb" {
  schema_id     = data.mso_schema.tf-hybrid-cloud.id
  template_name = data.mso_schema.tf-hybrid-cloud.template_name
  anp_name      = mso_schema_template_anp.tf-demo-app-1.name
  epg_name      = mso_schema_template_anp_epg.tf-mariadb.name
  name          = "tf-mariadb"
  expressions {
    key         = "Custom:EPG"
    operator    = "equals"
    value       = "MariaDB"
  }
}

### Contracts ###
resource "mso_schema_template_contract" "tf-inet-to-wordpress" {
  schema_id               = data.mso_schema.tf-hybrid-cloud.id
  template_name           = data.mso_schema.tf-hybrid-cloud.template_name
  contract_name           = "tf-inet-to-wordpress"
  display_name            = "Internet to WordPress"
  filter_type             = "bothWay"
  scope                   = "context"
  filter_relationships    = {
    # filter_schema_id      = mso_schema.tf-hybrid-cloud.id
    # filter_template_name  = mso_schema_template.tf-hc-prod.name
    filter_name           = data.mso_schema_template_filter_entry.tf-allow-icmp.name
  }
  directives = ["none"]
}

resource "mso_schema_template_contract_filter" "tf-inet-to-wordpress-2" {
  schema_id       = data.mso_schema.tf-hybrid-cloud.id
  template_name   = data.mso_schema.tf-hybrid-cloud.template_name
  contract_name   = mso_schema_template_contract.tf-inet-to-wordpress.contract_name
  filter_type     = "bothWay"
  filter_name     = data.mso_schema_template_filter_entry.tf-allow-ssh.name
  directives      = ["none"]
}

resource "mso_schema_template_contract_filter" "tf-inet-to-wordpress-3" {
  schema_id       = data.mso_schema.tf-hybrid-cloud.id
  template_name   = data.mso_schema.tf-hybrid-cloud.template_name
  contract_name   = mso_schema_template_contract.tf-inet-to-wordpress.contract_name
  filter_type     = "bothWay"
  filter_name     = data.mso_schema_template_filter_entry.tf-allow-http.name
  directives      = ["none"]
}

resource "mso_schema_template_contract" "tf-inet-to-mariadb" {
  schema_id               = data.mso_schema.tf-hybrid-cloud.id
  template_name           = data.mso_schema.tf-hybrid-cloud.template_name
  contract_name           = "tf-inet-to-mariadb"
  display_name            = "Internet to MariaDB"
  filter_type             = "bothWay"
  scope                   = "context"
  filter_relationships    = {
    # filter_schema_id      = mso_schema.tf-hybrid-cloud.id
    # filter_template_name  = mso_schema_template.tf-hc-prod.name
    filter_name           = data.mso_schema_template_filter_entry.tf-allow-icmp.name
  }
  directives = ["none"]
}

resource "mso_schema_template_contract_filter" "tf-inet-to-mariadb-2" {
  schema_id       = data.mso_schema.tf-hybrid-cloud.id
  template_name   = data.mso_schema.tf-hybrid-cloud.template_name
  contract_name   = mso_schema_template_contract.tf-inet-to-mariadb.contract_name
  filter_type     = "bothWay"
  filter_name     = data.mso_schema_template_filter_entry.tf-allow-ssh.name
  directives      = ["none"]
}

resource "mso_schema_template_contract" "tf-servers-to-inet" {
  schema_id               = data.mso_schema.tf-hybrid-cloud.id
  template_name           = data.mso_schema.tf-hybrid-cloud.template_name
  contract_name           = "tf-servers-to-inet"
  display_name            = "Servers to Internet"
  filter_type             = "bothWay"
  scope                   = "context"
  filter_relationships    = {
    # filter_schema_id      = mso_schema.tf-hybrid-cloud.id
    # filter_template_name  = mso_schema_template.tf-hc-prod.name
    filter_name           = data.mso_schema_template_filter_entry.tf-allow-any.name
  }
  directives = ["none"]
}

resource "mso_schema_template_contract" "tf-wordpress-to-mariadb" {
  schema_id               = data.mso_schema.tf-hybrid-cloud.id
  template_name           = data.mso_schema.tf-hybrid-cloud.template_name
  contract_name           = "tf-wordpress-to-mariadb"
  display_name            = "WordPress to MariaDB"
  filter_type             = "bothWay"
  scope                   = "context"
  filter_relationships    = {
    # filter_schema_id      = mso_schema.tf-hybrid-cloud.id
    # filter_template_name  = mso_schema_template.tf-hc-prod.name
    filter_name           = data.mso_schema_template_filter_entry.tf-allow-icmp.name
  }
  directives = ["none"]
}

resource "mso_schema_template_contract_filter" "tf-wordpress-to-mariadb-2" {
  schema_id       = data.mso_schema.tf-hybrid-cloud.id
  template_name   = data.mso_schema.tf-hybrid-cloud.template_name
  contract_name   = mso_schema_template_contract.tf-wordpress-to-mariadb.contract_name
  filter_type     = "bothWay"
  filter_name     = data.mso_schema_template_filter_entry.tf-allow-mysql.name
  directives      = ["none"]
}

### ExEPGs to Contracts
resource "mso_schema_template_external_epg_contract" "tf-public-1" {
  schema_id         = data.mso_schema.tf-hybrid-cloud.id
  template_name     = data.mso_schema.tf-hybrid-cloud.template_name
  contract_name     = mso_schema_template_contract.tf-inet-to-wordpress.contract_name
  external_epg_name = data.mso_schema_template_external_epg.tf-public.external_epg_name
  relationship_type = "consumer"
}

resource "mso_schema_template_external_epg_contract" "tf-public-2" {
  schema_id         = data.mso_schema.tf-hybrid-cloud.id
  template_name     = data.mso_schema.tf-hybrid-cloud.template_name
  contract_name     = mso_schema_template_contract.tf-inet-to-mariadb.contract_name
  external_epg_name = data.mso_schema_template_external_epg.tf-public.external_epg_name
  relationship_type = "consumer"
}

resource "mso_schema_template_external_epg_contract" "tf-public-3" {
  schema_id         = data.mso_schema.tf-hybrid-cloud.id
  template_name     = data.mso_schema.tf-hybrid-cloud.template_name
  contract_name     = mso_schema_template_contract.tf-servers-to-inet.contract_name
  external_epg_name = data.mso_schema_template_external_epg.tf-public.external_epg_name
  relationship_type = "provider"
}

### App EPG to Contracts ###
resource "mso_schema_template_anp_epg_contract" "tf-wordpress-1" {
  schema_id         = data.mso_schema.tf-hybrid-cloud.id
  template_name     = data.mso_schema.tf-hybrid-cloud.template_name
  anp_name          = mso_schema_template_anp.tf-demo-app-1.name
  epg_name          = mso_schema_template_anp_epg.tf-wordpress.name
  contract_name     = mso_schema_template_contract.tf-inet-to-wordpress.contract_name
  relationship_type = "provider"
}

resource "mso_schema_template_anp_epg_contract" "tf-wordpress-2" {
  schema_id         = data.mso_schema.tf-hybrid-cloud.id
  template_name     = data.mso_schema.tf-hybrid-cloud.template_name
  anp_name          = mso_schema_template_anp.tf-demo-app-1.name
  epg_name          = mso_schema_template_anp_epg.tf-wordpress.name
  contract_name     = mso_schema_template_contract.tf-wordpress-to-mariadb.contract_name
  relationship_type = "consumer"
}

resource "mso_schema_template_anp_epg_contract" "tf-wordpress-3" {
  schema_id         = data.mso_schema.tf-hybrid-cloud.id
  template_name     = data.mso_schema.tf-hybrid-cloud.template_name
  anp_name          = mso_schema_template_anp.tf-demo-app-1.name
  epg_name          = mso_schema_template_anp_epg.tf-wordpress.name
  contract_name     = data.mso_schema_template_contract.tf-servers-to-inet.contract_name
  relationship_type = "consumer"
}

resource "mso_schema_template_anp_epg_contract" "tf-mariadb-1" {
  schema_id         = data.mso_schema.tf-hybrid-cloud.id
  template_name     = data.mso_schema.tf-hybrid-cloud.template_name
  anp_name          = mso_schema_template_anp.tf-demo-app-1.name
  epg_name          = mso_schema_template_anp_epg.tf-mariadb.name
  contract_name     = mso_schema_template_contract.tf-inet-to-mariadb.contract_name
  relationship_type = "provider"
}

resource "mso_schema_template_anp_epg_contract" "tf-mariadb-2" {
  schema_id         = data.mso_schema.tf-hybrid-cloud.id
  template_name     = data.mso_schema.tf-hybrid-cloud.template_name
  anp_name          = mso_schema_template_anp.tf-demo-app-1.name
  epg_name          = mso_schema_template_anp_epg.tf-mariadb.name
  contract_name     = mso_schema_template_contract.tf-wordpress-to-mariadb.contract_name
  relationship_type = "provider"
}

resource "mso_schema_template_anp_epg_contract" "tf-mariadb-3" {
  schema_id         = data.mso_schema.tf-hybrid-cloud.id
  template_name     = data.mso_schema.tf-hybrid-cloud.template_name
  anp_name          = mso_schema_template_anp.tf-demo-app-1.name
  epg_name          = mso_schema_template_anp_epg.tf-mariadb.name
  contract_name     = data.mso_schema_template_contract.tf-servers-to-inet.contract_name
  relationship_type = "consumer"
}
