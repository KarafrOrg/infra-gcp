component "cloudflare_dns" {
  source = "./modules/cloudflare-dns"

  providers = {
    google = provider.google.main
  }

  inputs = {
    account_id  = var.cloudflare_account_id
    domain      = var.domain
    dns_records = var.dns_records
  }
}
