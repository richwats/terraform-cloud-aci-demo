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

data "mso_site" "AZURE-MEL" {
  name  = "AZURE-MEL"
}

### Common Tenant ###
data "mso_tenant" "production" {
  name = "Production"
  display_name = "Production"
}

### Common Schema
data "mso_schema" "tf-hybrid-cloud" {
  name          = "tf-hybrid-cloud"
}

### Common Template
data "mso_schema_template" "tf-hc-prod" {
  name        = "tf-hc-prod"
  schema_id   = data.mso_schema.tf-hybrid-cloud.id
}

### Common Production VRF
data "mso_schema_template_vrf" "tf-hc-prod"  {
  schema_id       = data.mso_schema.tf-hybrid-cloud.id
  template        = data.mso_schema_template.tf-hc-prod.name
  name            = "tf-hc-prod"
}
## Load Common ExEPGs
data "mso_schema_template_external_epg" "tf-public" {
  schema_id           = data.mso_schema.tf-hybrid-cloud.id
  template_name       = data.mso_schema_template.tf-hc-prod.name
  external_epg_name   = "tf-public"
}

## Load Common Contract
data "mso_schema_template_contract" "tf-servers-to-inet" {
  schema_id               = data.mso_schema.tf-hybrid-cloud.id
  template_name           = data.mso_schema_template.tf-hc-prod.name
  contract_name           = "tf-servers-to-inet"
}

## Load Common Filters
data "mso_schema_template_filter_entry" "tf-allow-any" {
  schema_id             = data.mso_schema.tf-hybrid-cloud.id
  template_name         = data.mso_schema_template.tf-hc-prod.name
  name                  = "tf-allow-any"
  entry_name            = "any"
}

data "mso_schema_template_filter_entry" "tf-allow-http" {
  schema_id             = data.mso_schema.tf-hybrid-cloud.id
  template_name         = data.mso_schema_template.tf-hc-prod.name
  name                  = "tf-allow-http"
  entry_name            = "http"
}

data "mso_schema_template_filter_entry" "tf-allow-icmp" {
  schema_id             = data.mso_schema.tf-hybrid-cloud.id
  template_name         = data.mso_schema_template.tf-hc-prod.name
  name                  = "tf-allow-icmp"
  entry_name            = "icmp"
}

data "mso_schema_template_filter_entry" "tf-allow-ssh" {
  schema_id             = data.mso_schema.tf-hybrid-cloud.id
  template_name         = data.mso_schema_template.tf-hc-prod.name
  name                  = "tf-allow-ssh"
  entry_name            = "ssh"
}


### Azure Site Specific Data

## Load VRF as Data ###
data "mso_schema_site_vrf" "tf-hc-prod-azure" {
  site_id   = data.mso_site.AZURE-MEL.id
  schema_id = data.mso_schema.tf-hybrid-cloud.id
  vrf_name  = data.mso_schema_template_vrf.tf-hc-prod.name
  # depends_on = [mso_rest.vrf-workaround]
}

data "mso_schema_site_vrf_region" "tf-hc-prod-az-mel" {
  schema_id     = data.mso_schema.tf-hybrid-cloud.id
  site_id       = data.mso_site.AZURE-MEL.id
  vrf_name      = data.mso_schema_template_vrf.tf-hc-prod.name
  region_name   = "australiasoutheast"
  # depends_on = [mso_rest.vrf-workaround]
}

## Create New Subnets for K8S Applciation
resource "mso_schema_site_vrf_region_cidr_subnet" "tf-hc-prod-az-mel-1" {
  schema_id     = data.mso_schema.tf-hybrid-cloud.id
  template_name = data.mso_schema_template.tf-hc-prod.name
  site_id       = data.mso_site.AZURE-MEL.id
  vrf_name      = data.mso_schema_template_vrf.tf-hc-prod.name
  region_name   = "australiasoutheast"
  cidr_ip       = "10.112.0.0/16"
  ip            = "10.112.5.0/24"
  zone          = "1"
  usage         = "AKS"
}

resource "mso_schema_site_vrf_region_cidr_subnet" "tf-hc-prod-az-mel-2" {
  schema_id     = data.mso_schema.tf-hybrid-cloud.id
  template_name = data.mso_schema_template.tf-hc-prod.name
  site_id       = data.mso_site.AZURE-MEL.id
  vrf_name      = data.mso_schema_template_vrf.tf-hc-prod.name
  region_name   = "australiasoutheast"
  cidr_ip       = "10.112.0.0/16"
  ip            = "10.112.6.0/24"
  zone          = "2"
  usage         = "AKS"
}

### New Template for AKS K8S (AKS) ###

resource "mso_schema_template" "tf-k8s-aks" {
  schema_id = data.mso_schema.tf-hybrid-cloud.id
  name = "tf-aks"
  display_name = "tf-aks"
  tenant_id = data.mso_tenant.production.id
}

### Associated Template/Schema with Site
resource "mso_schema_site" "tf-k8s-aks" {
  schema_id       = data.mso_schema.tf-hybrid-cloud.id
  site_id         = data.mso_site.AZURE-MEL.id
  template_name   = mso_schema_template.tf-k8s-aks.name
}


### Application Network Profile ###
resource "mso_schema_template_anp" "tf-aks-1" {
  schema_id       = data.mso_schema.tf-hybrid-cloud.id
  # template      = data.mso_schema.tf-hybrid-cloud.template_name
  template        = mso_schema_template.tf-k8s-aks.name
  name            = "tf-aks-1"
  display_name    = "Terraform K8S AKS Demo 1"
}

# ### Azure Site Specific Configuration

/*

Error: "Resource Not Found: AnpDelta with name tf-aks-1 not found in List()"{}

  on modules/apps/k8s-aks/main.tf line 192, in resource "mso_schema_site_anp_epg_selector" "tf-k8s-worker-1":
 192: resource "mso_schema_site_anp_epg_selector" "tf-k8s-worker-1" {



Error: "Resource Not Found: AnpDelta with name tf-aks-1 not found in List()"{}

  on modules/apps/k8s-aks/main.tf line 210, in resource "mso_schema_site_anp_epg_selector" "tf-k8s-worker-2":
 210: resource "mso_schema_site_anp_epg_selector" "tf-k8s-worker-2" {



- Deploy First?

*/

## Force Deploy to Azure ##
resource "mso_schema_template_deploy" "azure_mel_before" {
  schema_id     = data.mso_schema.tf-hybrid-cloud.id
  template_name = mso_schema_template.tf-k8s-aks.name
}

resource "mso_schema_template_deploy" "azure_mel_after" {
  schema_id     = data.mso_schema.tf-hybrid-cloud.id
  template_name = mso_schema_template.tf-k8s-aks.name

  depends_on = [
    mso_schema_site_anp_epg_selector.tf-k8s-worker-1,
    mso_schema_site_anp_epg_selector.tf-k8s-worker-2
  ]
}

resource "mso_schema_site_anp_epg_selector" "tf-k8s-worker-1" {
  schema_id     = data.mso_schema.tf-hybrid-cloud.id
  site_id       = data.mso_site.AZURE-MEL.id
  # template_name = data.mso_schema_template.tf-hc-prod.name
  template_name = mso_schema_template.tf-k8s-aks.name
  anp_name      = mso_schema_template_anp.tf-aks-1.name
  epg_name      = mso_schema_template_anp_epg.tf-k8s-worker.name
  name          = "tf-azure-sub-5"
  expressions {
    key         = "ipAddress"
    operator    = "equals"
    value       = "10.112.5.0/24"
  }
  depends_on = [
    mso_schema_template_deploy.azure_mel_before
  ]
}

resource "mso_schema_site_anp_epg_selector" "tf-k8s-worker-2" {
  schema_id     = data.mso_schema.tf-hybrid-cloud.id
  site_id       = data.mso_site.AZURE-MEL.id
  # template_name = data.mso_schema_template.tf-hc-prod.name
  template_name = mso_schema_template.tf-k8s-aks.name
  anp_name      = mso_schema_template_anp.tf-aks-1.name
  epg_name      = mso_schema_template_anp_epg.tf-k8s-worker.name
  name          = "tf-azure-sub-6"
  expressions {
    key         = "ipAddress"
    operator    = "equals"
    value       = "10.112.6.0/24"
  }
  depends_on = [
    mso_schema_template_deploy.azure_mel_before
  ]
}

# ### Ex EPGs to Contracts ###
# Configured by AWS K8S

# resource "mso_schema_template_external_epg_contract" "tf-public-1" {
#   schema_id         = data.mso_schema.tf-hybrid-cloud.id
#   template_name     = data.mso_schema_template.tf-hc-prod.name
#   # template_name     = mso_schema_template.tf-k8s-aks.name
#   contract_name     = mso_schema_template_contract.tf-inet-to-k8s.contract_name
#   external_epg_name = data.mso_schema_template_external_epg.tf-public.external_epg_name
#   relationship_type = "consumer"
# }

### App EPGs
resource "mso_schema_template_anp_epg" "tf-k8s-worker" {
  schema_id                   = data.mso_schema.tf-hybrid-cloud.id
  # template_name = data.mso_schema_template.tf-hc-prod.name
  template_name               = mso_schema_template.tf-k8s-aks.name
  anp_name                    = mso_schema_template_anp.tf-aks-1.name
  name                        = "tf-k8s-worker"
  bd_name                     = "unspecified"
  vrf_name                    = data.mso_schema_template_vrf.tf-hc-prod.name
  vrf_template_name           = data.mso_schema_template.tf-hc-prod.name
  display_name                = "K8S Worker Node"
}

### App EPG to Contracts ###
# Configured by AWS K8S

# - Need "contract_template_name"
#
# resource "mso_schema_template_anp_epg_contract" "tf-k8s-worker-1" {
#   schema_id         = data.mso_schema.tf-hybrid-cloud.id
#   # template_name     = data.mso_schema_template.tf-hc-prod.name
#   template_name     = mso_schema_template.tf-k8s-aks.name
#   anp_name          = mso_schema_template_anp.tf-aks-1.name
#   epg_name          = mso_schema_template_anp_epg.tf-k8s-worker.name
#   contract_name     = data.mso_schema_template_contract.tf-servers-to-inet.contract_name
#   contract_template_name = data.mso_schema_template.tf-hc-prod.name
#   relationship_type = "consumer"
# }
#
# resource "mso_schema_template_anp_epg_contract" "tf-k8s-worker-2" {
#   schema_id         = data.mso_schema.tf-hybrid-cloud.id
#   # template_name     = data.mso_schema_template.tf-hc-prod.name
#   template_name     = mso_schema_template.tf-k8s-aks.name
#   anp_name          = mso_schema_template_anp.tf-aks-1.name
#   epg_name          = mso_schema_template_anp_epg.tf-k8s-worker.name
#   contract_name     = mso_schema_template_contract.tf-inet-to-k8s.contract_name
#   contract_template_name = data.mso_schema_template.tf-hc-prod.name
#   relationship_type = "provider"
# }

# ### Contracts ###
# Configured by AWS K8S

# resource "mso_schema_template_contract" "tf-inet-to-k8s" {
#   schema_id               = data.mso_schema.tf-hybrid-cloud.id
#   template_name           = data.mso_schema_template.tf-hc-prod.name
#   # template_name           = mso_schema_template.tf-k8s-aks.name
#   contract_name           = "tf-inet-to-k8s"
#   display_name            = "Internet to K8S Workers"
#   filter_type             = "bothWay"
#   scope                   = "context"
#   filter_relationships    = {
#     # filter_schema_id      = mso_schema.tf-hybrid-cloud.id
#     # filter_template_name  = mso_schema_template.tf-hc-prod.name
#     filter_name           = data.mso_schema_template_filter_entry.tf-allow-any.name
#   }
#   directives = ["none"]
# }
