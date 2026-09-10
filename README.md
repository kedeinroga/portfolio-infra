# portfolio-infra

Terraform de la zona `kedein.com` para lo que necesita el portfolio: correo personal (MX/SPF) y
el proyecto Cloudflare Pages del apex. **Independiente** de la infraestructura de `finance`
(GCP, Neon, subdominios) — ese otro Terraform, si existe, vive en un repo separado y no se toca
desde aquí. El plan y el runbook completos de la migración viven en el workspace privado, fuera
de este repo.

## Estado actual (aplicado)

`kedein.com` ya corre sobre Cloudflare — nameservers cambiados en el registrador, zona activa:

| Recurso | Estado |
|---|---|
| Nameservers | `bingo.ns.cloudflare.com` / `yevgen.ns.cloudflare.com` |
| MX (correo personal, `eforward1..5`) | Preservados, gestionados por Terraform (`cloudflare_record.mx_eforward`) |
| TXT SPF | Preservado, gestionado por Terraform (`cloudflare_record.spf_apex`) |
| Proyecto Pages `portfolio` | Activo, subdominio `portfolio-8al.pages.dev` |
| Dominio custom `kedein.com` sobre el proyecto | `active` (certificado emitido, `cloudflare_pages_domain.portfolio`) |
| `CNAME` del apex → `portfolio-8al.pages.dev` | Activo, proxied (`cloudflare_record.apex_cname`) |

Limpieza hecha a mano fuera de Terraform (no se puede expresar como recurso sin arriesgar el
correo, quedó documentado aquí en vez de en código):

- Se borró un TXT SPF **duplicado** que el Quick Scan de Cloudflare había importado antes del
  primer `apply` (Terraform terminó gestionando el suyo).
- Se borró el `A` huérfano de `www.kedein.com` (apuntaba a Firebase App Hosting, sin uso tras el
  corte del apex a Cloudflare Pages).
- El TXT `fah-claim=...` de verificación de Firebase quedó sin tocar (inofensivo; se puede borrar
  cuando se decida dar de baja Firebase App Hosting — fuera de alcance de este repo).

## Qué es manual y por qué

| Paso | Por qué es manual |
|---|---|
| Crear la cuenta Cloudflare y agregar la zona `kedein.com` | Terraform solo administra registros *dentro* de una zona existente (`data.cloudflare_zone`) |
| Token de API y Account ID | Se crean en el dashboard de Cloudflare, no hay forma de automatizarlo sin credenciales previas |
| Cambio de nameservers en Namecheap | Alto impacto (correo + dominio en vivo), deliberadamente fuera de cualquier automatización |

## State

**Local** (`terraform.tfstate`, gitignored). Es un puñado de recursos de un operador único — no
justifica un backend remoto. Si se decide compartir infraestructura con `finance` más adelante, se
migra con `terraform init -migrate-state`.

## Reaplicar / hacer cambios

```bash
terraform plan -out=tf.plan   # revisar antes de aplicar, siempre
terraform apply tf.plan
```

Si algún registro se recrea desde cero en una zona nueva (por ejemplo, migrando a otra cuenta) y
Cloudflare ya importó MX/TXT vía su Quick Scan al agregar el sitio, el primer `apply` va a fallar
con `expected DNS record to not already be present but already exists` en esos registros — hay que
importarlos al state en vez de dejar que Terraform los cree:

```bash
terraform import 'cloudflare_record.mx_eforward["eforward1.registrar-servers.com"]' "<zone_id>/<record_id>"
```

(uno por cada MX; los IDs se obtienen listando `dns_records` con la API de Cloudflare). El `A` que
el mismo Quick Scan importa para el apex, en cambio, sí hay que borrarlo a mano antes del apply:
un `A` y el `CNAME` de `apex_cname` no pueden coexistir en el mismo nombre.
