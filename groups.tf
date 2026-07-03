resource "azuread_group" "finance_users" {
  display_name     = "SG-Finance-Users-TF"
  security_enabled = true
  description      = "Grupo de seguranca para o time de Finance"
}

resource "azuread_group" "it_admins" {
  display_name     = "SG-IT-Admins-TF"
  security_enabled = true
  description      = "Grupo de seguranca para o time de IT"
}