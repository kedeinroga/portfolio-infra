variable "cloudflare_api_token" {
  description = "Token con permisos Zone:DNS:Edit, Zone:Zone:Read y Account:Cloudflare Pages:Edit, acotado a la zona kedein.com y a la cuenta de abajo."
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Account ID de la cuenta Cloudflare que alberga la zona kedein.com."
  type        = string
}
