# output "AWS-SYD-ID" {
#   value = data.mso_site.AWS-SYD.id
# }
#
# output "AZURE-MEL-ID" {
#   value = data.mso_site.AZURE-MEL.id
# }

/*

Outputs required
- VPC details
- Subnet details

*/

# output "aws-syd-prod-vrf" {
#   value = data.mso_schema_site_vrf.tf-hc-prod-aws
# }
#
# output "aws-syd-reg" {
#   value = data.mso_schema_site_vrf_region.tf-hc-prod-aws-syd
# }

output "test-schema" {
  value = data.mso_schema.tf-hybrid-cloud
}
