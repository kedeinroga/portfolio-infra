# La zona kedein.com se agrega a mano en el dashboard de Cloudflare (paso previo, fuera de este
# Terraform): el cambio de nameservers en el registrador exige que la zona ya exista en Cloudflare.
# Terraform solo administra registros dentro de ella, no la zona en sí.
data "cloudflare_zone" "kedein" {
  name = "kedein.com"
}

# --- Correo personal (apex) — NUNCA tocar el MX/SPF: cortarlo pierde el correo real. ---

resource "cloudflare_record" "mx_eforward" {
  for_each = {
    "eforward1.registrar-servers.com" = 10
    "eforward2.registrar-servers.com" = 10
    "eforward3.registrar-servers.com" = 10
    "eforward4.registrar-servers.com" = 15
    "eforward5.registrar-servers.com" = 20
  }

  zone_id  = data.cloudflare_zone.kedein.zone_id
  name     = "kedein.com"
  type     = "MX"
  content  = each.key
  priority = each.value
  proxied  = false
  ttl      = 300
}

resource "cloudflare_record" "spf_apex" {
  zone_id = data.cloudflare_zone.kedein.zone_id
  name    = "kedein.com"
  type    = "TXT"
  content = "v=spf1 include:spf.efwd.registrar-servers.com ~all"
  ttl     = 300
}

# --- Apex → portfolio (Cloudflare Pages) ---

# Reemplaza el A que apuntaba a Firebase App Hosting. CNAME flattening de Cloudflare: puede
# coexistir con el MX/TXT de arriba porque el proxy lo resuelve a nivel de borde, algo que DNS
# estándar no permitiría con un CNAME normal en el apex.
#
# Antes del primer apply: borrar a mano en el dashboard el registro A que el Quick Scan de
# Cloudflare importó para "kedein.com" (proxied, apuntando a Firebase) — un A y un CNAME no pueden
# coexistir en el mismo nombre y la creación de este recurso falla si ese A sigue ahí.
resource "cloudflare_record" "apex_cname" {
  zone_id = data.cloudflare_zone.kedein.zone_id
  name    = "kedein.com"
  type    = "CNAME"
  content = cloudflare_pages_project.portfolio.subdomain
  proxied = true
  ttl     = 1 # automático, requerido cuando proxied = true
}
