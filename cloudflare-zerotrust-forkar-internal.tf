# ═══════════════════════════════════════════════════════════════════════════════
#  CLOUDFLARE ZERO TRUST (ACCESS) CONFIGURATION FOR FORKAR INTERNAL & CSIMS
#  Target: forkar-internal.cokistudios.com & csims.cokistudios.com
#  Rule: Only authenticated Microsoft accounts ending in @cokistudios.com
# ═══════════════════════════════════════════════════════════════════════════════

terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

variable "cloudflare_account_id" {
  type        = string
  description = "The Cloudflare Account ID for Coki Studios"
}

variable "cloudflare_zone_id" {
  type        = string
  description = "The Zone ID for cokistudios.com"
}

variable "azure_idp_id" {
  type        = string
  description = "The ID of the Azure AD / Microsoft Entra ID provider in Cloudflare Access"
  default     = ""
}

# 1. Reusable Access Policy for Coki Studios Team (@cokistudios.com via Microsoft)
resource "cloudflare_zero_trust_access_policy" "coki_studios_team_only" {
  account_id = var.cloudflare_account_id
  name       = "Allow Coki Studios Team (@cokistudios.com via Microsoft)"
  decision   = "allow"

  include {
    email_domain {
      domain = "cokistudios.com"
    }
  }
}

# 2. Access Application for Forkar Internal
resource "cloudflare_zero_trust_access_application" "forkar_internal" {
  account_id                = var.cloudflare_account_id
  name                      = "Forkar Internal"
  domain                    = "forkar-internal.cokistudios.com"
  type                      = "self_hosted"
  session_duration          = "24h"
  auto_redirect_to_identity = true
  allowed_idps              = var.azure_idp_id != "" ? [var.azure_idp_id] : null
  app_launcher_visible      = true
  policies                  = [cloudflare_zero_trust_access_policy.coki_studios_team_only.id]

  cors_headers {
    allowed_methods = ["GET", "POST", "OPTIONS"]
    allowed_origins = ["https://forkar.cokistudios.com", "https://cokistudios.com"]
    allow_credentials = true
    max_age           = 86400
  }
}

# 3. Access Application for CSIMS (Coki Studios Internal Messaging Service)
resource "cloudflare_zero_trust_access_application" "csims_internal" {
  account_id                = var.cloudflare_account_id
  name                      = "CSIMS (Coki Studios Internal Messaging Service)"
  domain                    = "csims.cokistudios.com"
  type                      = "self_hosted"
  session_duration          = "24h"
  auto_redirect_to_identity = true
  allowed_idps              = var.azure_idp_id != "" ? [var.azure_idp_id] : null
  app_launcher_visible      = true
  policies                  = [cloudflare_zero_trust_access_policy.coki_studios_team_only.id]
}
