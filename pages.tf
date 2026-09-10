# El build/deploy real lo hace el workflow de GitHub Actions de portfolio-analytics
# (wrangler pages deploy); este archivo solo declara el proyecto y su dominio custom.

resource "cloudflare_pages_project" "portfolio" {
  account_id        = var.cloudflare_account_id
  name              = "portfolio"
  production_branch = "main"
}

resource "cloudflare_pages_domain" "portfolio" {
  account_id   = var.cloudflare_account_id
  project_name = cloudflare_pages_project.portfolio.name
  domain       = "kedein.com"
}
