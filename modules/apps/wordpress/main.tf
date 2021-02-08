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
  schema_id       = mso_schema.tf-hybrid-cloud.id
  template        = mso_schema.tf-hybrid-cloud.template_name
  name            = "tf-hc-prod"
}

## Load Common ExEPGs
data "mso_schema_template_external_epg" "tf-public" {
  schema_id           = data.mso_schema.tf-hybrid-cloud.id
  template_name       = data.mso_schema.tf-hybrid-cloud.template_name
  external_epg_name   = "tf-public"

## Load Common ExEPGs
data "mso_schema_template_external_epg" "tf-public" {
  schema_id           = data.mso_schema.tf-hybrid-cloud.id
  template_name       = data.mso_schema.tf-hybrid-cloud.template_name
  external_epg_name   = "tf-public"
}

## Load Common Filters
data "mso_schema_template_filter_entry" "tf-allow-any" {
  schema_id             = data.mso_schema.tf-hybrid-cloud.id
  template_name         = data.mso_schema.tf-hybrid-cloud.template_name
  name                  = "tf-allow-any"
}

data "mso_schema_template_filter_entry" "tf-allow-http" {
  schema_id             = data.mso_schema.tf-hybrid-cloud.id
  template_name         = data.mso_schema.tf-hybrid-cloud.template_name
  name                  = "tf-allow-http"
}

data "mso_schema_template_filter_entry" "tf-allow-icmp" {
  schema_id             = data.mso_schema.tf-hybrid-cloud.id
  template_name         = data.mso_schema.tf-hybrid-cloud.template_name
  name                  = "tf-allow-icmp"
}

data "mso_schema_template_filter_entry" "tf-allow-mysql" {
  schema_id             = data.mso_schema.tf-hybrid-cloud.id
  template_name         = data.mso_schema.tf-hybrid-cloud.template_name
  name                  = "tf-allow-mysql"
}

data "mso_schema_template_filter_entry" "tf-allow-ssh" {
  schema_id             = data.mso_schema.tf-hybrid-cloud.id
  template_name         = data.mso_schema.tf-hybrid-cloud.template_name
  name                  = "tf-allow-ssh"
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

### ExEPGs
data "mso_schema_template_external_epg" "tf-public" {
  schema_id           = data.mso_schema.tf-hybrid-cloud.id
  template_name       = data.mso_schema.tf-hybrid-cloud.template_name
  external_epg_name   = "tf-public"

### Ex EPGs to Contracts ###

## K8S
resource "mso_schema_template_external_epg_contract" "tf-public-4" {
  schema_id         = data.mso_schema.tf-hybrid-cloud.id
  template          = data.mso_schema.tf-hybrid-cloud.template_name
  contract_name     = mso_schema_template_contract.tf-inet-to-k8s.contract_name
  external_epg_name = data.mso_schema_template_external_epg.tf-public.external_epg_name
  relationship_type = "consumer"
}

## WordPress
resource "mso_schema_template_external_epg_contract" "tf-public-1" {
  schema_id         = data.mso_schema.tf-hybrid-cloud.id
  template          = data.mso_schema.tf-hybrid-cloud.template_name
  contract_name     = mso_schema_template_contract.tf-inet-to-wordpress.contract_name
  external_epg_name = data.mso_schema_template_external_epg.tf-public.external_epg_name
  relationship_type = "consumer"
}

resource "mso_schema_template_external_epg_contract" "tf-public-2" {
  schema_id         = data.mso_schema.tf-hybrid-cloud.id
  template          = data.mso_schema.tf-hybrid-cloud.template_name
  contract_name     = mso_schema_template_contract.tf-inet-to-mariadb.contract_name
  external_epg_name = data.mso_schema_template_external_epg.tf-public.external_epg_name
  relationship_type = "consumer"
}

resource "mso_schema_template_external_epg_contract" "tf-public-3" {
  schema_id         = data.mso_schema.tf-hybrid-cloud.id
  template          = data.mso_schema.tf-hybrid-cloud.template_name
  contract_name     = mso_schema_template_contract.tf-servers-to-inet.contract_name
  external_epg_name = data.mso_schema_template_external_epg.tf-public.external_epg_name
  relationship_type = "provider"
}

### App EPGs

## K8S
resource "mso_schema_template_anp_epg" "tf-k8s-worker" {
  schema_id                   = data.mso_schema.tf-hybrid-cloud.id
  template_name               = data.mso_schema.tf-hybrid-cloud.template_name
  anp_name                    = mso_schema_template_anp.tf-k8s-1.name
  name                        = "tf-k8s-worker"
  bd_name                     = "unspecified"
  vrf_name                    = data.mso_schema_template_vrf.tf-hc-prod.name
  display_name                = "K8S Worker Node"
}

## WordPress
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
  vrf_name                    = mso_schema_template_vrf.tf-hc-prod.name
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

### App EPG to Contracts ###

## K8S
resource "mso_schema_template_anp_epg_contract" "tf-k8s-worker-1" {
  schema_id         = data.mso_schema.tf-hybrid-cloud.id
  template_name     = data.mso_schema.tf-hybrid-cloud.template_name
  anp_name          = mso_schema_template_anp.tf-k8s-1.name
  epg_name          = mso_schema_template_anp_epg.tf-k8s-worker.name
  contract_name     = data.mso_schema_template_contract.tf-servers-to-inet.contract_name
  relationship_type = "consumer"
}

resource "mso_schema_template_anp_epg_contract" "tf-k8s-worker-2" {
  schema_id         = data.mso_schema.tf-hybrid-cloud.id
  template_name     = data.mso_schema.tf-hybrid-cloud.template_name
  anp_name          = mso_schema_template_anp.tf-k8s-1.name
  epg_name          = mso_schema_template_anp_epg.tf-k8s-worker.name
  contract_name     = data.mso_schema_template_contract.tf-servers-to-inet.contract_name
  relationship_type = "provider"
}

## WordPress

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

### Contracts ###

## k8s
resource "mso_schema_template_contract" "tf-inet-to-k8s" {
  schema_id               = data.mso_schema.tf-hybrid-cloud.id
  template_name           = data.mso_schema.tf-hybrid-cloud.template_name
  contract_name           = "tf-inet-to-k8s"
  display_name            = "Internet to K8S Workers"
  filter_type             = "bothWay"
  scope                   = "context"
  filter_relationships    = {
    # filter_schema_id      = mso_schema.tf-hybrid-cloud.id
    # filter_template_name  = mso_schema_template.tf-hc-prod.name
    filter_name           = data.mso_schema_template_filter_entry.tf-allow-any.name
  }
  directives = ["none"]
}

# resource "mso_schema_template_contract" "tf-eks-cluster-to-node" {
#   schema_id               = mso_schema.tf-hybrid-cloud.id
#   template_name           = mso_schema.tf-hybrid-cloud.template_name
#   contract_name           = "tf-eks-cluster-to-node"
#   display_name            = "Cluster to K8S Workers"
#   filter_type             = "bothWay"
#   scope                   = "context"
#   filter_relationships    = {
#     filter_name           = mso_schema_template_filter_entry.tf-allow-any.name
#   }
#   directives = ["none"]
# }

# resource "mso_schema_template_contract_filter" "tf-inet-to-k8s-2" {
#   schema_id       = mso_schema.tf-hybrid-cloud.id
#   template_name   = mso_schema.tf-hybrid-cloud.template_name
#   contract_name   = mso_schema_template_contract.tf-inet-to-k8s.contract_name
#   filter_type     = "bothWay"
#   filter_name     = mso_schema_template_filter_entry.tf-allow-ssh.name
#   directives      = ["none"]
# }

# resource "mso_schema_template_contract_filter" "tf-inet-to-k8s-2" {
#   schema_id       = mso_schema.tf-hybrid-cloud.id
#   template_name   = mso_schema.tf-hybrid-cloud.template_name
#   contract_name   = mso_schema_template_contract.tf-inet-to-k8s.contract_name
#   filter_type     = "bothWay"
#   filter_name     = mso_schema_template_filter_entry.tf-allow-http-1.name
#   directives      = ["none"]
# }

# resource "mso_schema_template_contract_filter" "tf-inet-to-k8s-3" {
#   schema_id       = mso_schema.tf-hybrid-cloud.id
#   template_name   = mso_schema.tf-hybrid-cloud.template_name
#   contract_name   = mso_schema_template_contract.tf-inet-to-k8s.contract_name
#   filter_type     = "bothWay"
#   filter_name     = mso_schema_template_filter_entry.tf-allow-61678.name
#   directives      = ["none"]
# }

# resource "mso_schema_template_contract_filter" "tf-inet-to-k8s-4" {
#   schema_id       = mso_schema.tf-hybrid-cloud.id
#   template_name   = mso_schema.tf-hybrid-cloud.template_name
#   contract_name   = mso_schema_template_contract.tf-inet-to-k8s.contract_name
#   filter_type     = "bothWay"
#   filter_name     = mso_schema_template_filter_entry.tf-allow-dns-1.name
#   directives      = ["none"]
# }

# resource "mso_schema_template_contract_filter" "tf-inet-to-k8s-5" {
#   schema_id       = mso_schema.tf-hybrid-cloud.id
#   template_name   = mso_schema.tf-hybrid-cloud.template_name
#   contract_name   = mso_schema_template_contract.tf-inet-to-k8s.contract_name
#   filter_type     = "bothWay"
#   filter_name     = mso_schema_template_filter_entry.tf-allow-50051.name
#   directives      = ["none"]
# }
#
# resource "mso_schema_template_contract_filter" "tf-inet-to-k8s-6" {
#   schema_id       = mso_schema.tf-hybrid-cloud.id
#   template_name   = mso_schema.tf-hybrid-cloud.template_name
#   contract_name   = mso_schema_template_contract.tf-inet-to-k8s.contract_name
#   filter_type     = "bothWay"
#   filter_name     = mso_schema_template_filter_entry.tf-allow-10250.name
#   directives      = ["none"]
# }

# resource "mso_schema_template_contract_filter" "tf-inet-to-k8s-7" {
#   schema_id       = mso_schema.tf-hybrid-cloud.id
#   template_name   = mso_schema.tf-hybrid-cloud.template_name
#   contract_name   = mso_schema_template_contract.tf-inet-to-k8s.contract_name
#   filter_type     = "bothWay"
#   filter_name     = mso_schema_template_filter_entry.tf-allow-range-1.name
#   directives      = ["none"]
# }

## WordPress
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




## K8S

# resource "mso_schema_template_filter_entry" "tf-allow-10250" {
#   schema_id             = mso_schema.tf-hybrid-cloud.id
#   template_name         = mso_schema.tf-hybrid-cloud.template_name
#   name                  = "tf-allow-10250"
#   display_name          = "Allow 10250"
#   entry_name            = "10250"
#   entry_display_name    = "10250"
#   entry_description     = "Allow Any to Destination TCP 10250"
#   ether_type            = "ip"
#   ip_protocol           = "tcp"
#   destination_from      = "10250"
#   destination_to        = "10250"
# }
#
#
# resource "mso_schema_template_filter_entry" "tf-allow-50051" {
#   schema_id             = mso_schema.tf-hybrid-cloud.id
#   template_name         = mso_schema.tf-hybrid-cloud.template_name
#   name                  = "tf-allow-50051"
#   display_name          = "Allow 50051"
#   entry_name            = "50051"
#   entry_display_name    = "50051"
#   entry_description     = "Allow Any to Destination TCP 50051"
#   ether_type            = "ip"
#   ip_protocol           = "tcp"
#   destination_from      = "50051"
#   destination_to        = "50051"
# }
#
# resource "mso_schema_template_filter_entry" "tf-allow-61678" {
#   schema_id             = mso_schema.tf-hybrid-cloud.id
#   template_name         = mso_schema.tf-hybrid-cloud.template_name
#   name                  = "tf-allow-61678"
#   display_name          = "Allow 61678"
#   entry_name            = "61678"
#   entry_display_name    = "61678"
#   entry_description     = "Allow Any to Destination TCP 61678"
#   ether_type            = "ip"
#   ip_protocol           = "tcp"
#   destination_from      = "61678"
#   destination_to        = "61678"
# }

# resource "mso_schema_template_filter_entry" "tf-allow-range-1" {
#   schema_id             = mso_schema.tf-hybrid-cloud.id
#   template_name         = mso_schema.tf-hybrid-cloud.template_name
#   name                  = "tf-allow-range-1"
#   display_name          = "Allow High Ports"
#   entry_name            = "highPorts"
#   entry_display_name    = "High Ports"
#   entry_description     = "Allow Any to High Ports"
#   ether_type            = "ip"
#   ip_protocol           = "tcp"
#   destination_from      = "1025"
#   destination_to        = "65535"
# }

# resource "mso_schema_template_filter_entry" "tf-allow-dns-1" {
#   schema_id             = mso_schema.tf-hybrid-cloud.id
#   template_name         = mso_schema.tf-hybrid-cloud.template_name
#   name                  = "tf-allow-dns"
#   display_name          = "Allow DNS"
#   entry_name            = "dns-udp"
#   entry_display_name    = "dns-udp"
#   entry_description     = "Allow Any to Destination DNS UDP 53"
#   ether_type            = "ip"
#   ip_protocol           = "udp"
#   destination_from      = "dns"
#   destination_to        = "dns"
# }
#
# resource "mso_schema_template_filter_entry" "tf-allow-dns-2" {
#   schema_id             = mso_schema.tf-hybrid-cloud.id
#   template_name         = mso_schema.tf-hybrid-cloud.template_name
#   name                  = "tf-allow-dns"
#   display_name          = "Allow DNS"
#   entry_name            = "dns-tcp"
#   entry_display_name    = "dns-tcp"
#   entry_description     = "Allow Any to Destination DNS TCP 53"
#   ether_type            = "ip"
#   ip_protocol           = "tcp"
#   destination_from      = "dns"
#   destination_to        = "dns"
# }
#
# resource "mso_schema_template_filter_entry" "tf-allow-dns-3" {
#   schema_id             = mso_schema.tf-hybrid-cloud.id
#   template_name         = mso_schema.tf-hybrid-cloud.template_name
#   name                  = "tf-allow-dns"
#   display_name          = "Allow DNS"
#   entry_name            = "dns-9153"
#   entry_display_name    = "dns-9153"
#   entry_description     = "Allow Any to Destination DNS TCP 9153"
#   ether_type            = "ip"
#   ip_protocol           = "tcp"
#   destination_from      = "9153"
#   destination_to        = "9153"
# }

### AWS Site Specific

# resource "mso_schema_site_anp_epg_selector" "tf-k8s-worker-1" {
#   schema_id     = mso_schema.tf-hybrid-cloud.id
#   site_id       = data.mso_site.AWS-SYD.id
#   template_name = mso_schema.tf-hybrid-cloud.template_name
#   anp_name      = mso_schema_template_anp.tf-k8s-1.name
#   epg_name      = mso_schema_template_anp_epg.tf-k8s-worker.name
#   name          = "tf-aws-subnet-3"
#   expressions {
#     key         = "ipAddress"
#     operator    = "equals"
#     value       = "10.111.3.0/24"
#   }
# }
#
# resource "mso_schema_site_anp_epg_selector" "tf-k8s-worker-2" {
#   schema_id     = mso_schema.tf-hybrid-cloud.id
#   site_id       = data.mso_site.AWS-SYD.id
#   template_name = mso_schema.tf-hybrid-cloud.template_name
#   anp_name      = mso_schema_template_anp.tf-k8s-1.name
#   epg_name      = mso_schema_template_anp_epg.tf-k8s-worker.name
#   name          = "tf-aws-subnet-4"
#   expressions {
#     key         = "ipAddress"
#     operator    = "equals"
#     value       = "10.111.4.0/24"
#   }
# }

# ### DEPLOY
#
# resource "mso_schema_template_deploy" "aws_syd" {
#   schema_id     = mso_schema.tf-hybrid-cloud.id
#   template_name = mso_schema.tf-hybrid-cloud.template_name
#   site_id       = data.mso_site.AWS-SYD.id
#   undeploy      = false
# }
