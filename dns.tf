# La zona kedein.com se agrega a mano en el dashboard de Cloudflare (paso previo, fuera de este
# Terraform): el cambio de nameservers en el registrador exige que la zona ya exista en Cloudflare.
# Terraform solo administra registros dentro de ella, no la zona en sí.
data "cloudflare_zone" "kedein" {
  name = "kedein.com"
}

# --- Correo personal (apex) ---
#
# El MX/SPF de reenvío de Namecheap (eforward*) que este Terraform gestionaba se retiró
# (decisión 2026-09-11): no había ninguna dirección @kedein.com en uso real (confirmado: el panel
# de Namecheap ya no deja gestionar redirects desde que los nameservers son de Cloudflare, y no
# hay memoria de haber usado ninguna dirección de ese dominio). El apex pasa a usar Cloudflare
# Email Routing en su lugar (dashboard → Email Routing → Onboard Domain), que publica y gestiona
# sus propios MX/SPF/DKIM directamente — por fuera de Terraform, igual que ya se documentó para
# `finance-inbound.kedein.com` en `finance-infra` (Cloudflare es dueño de esos registros, no
# Terraform, para no competir con lo que el producto gestiona internamente).

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
