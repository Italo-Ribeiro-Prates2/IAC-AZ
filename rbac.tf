data "azurerm_resource_group" "it_shared" {
  name = "rg-it-shared"
}

data "azurerm_resource_group" "finance_prod" {
  name = "rg-finance-prod"
}

resource "azurerm_role_assignment" "it_admins_contributor" {
  scope                = data.azurerm_resource_group.it_shared.id
  role_definition_name = "Contributor"
  principal_id         = azuread_group.it_admins.object_id
}

resource "azurerm_role_assignment" "finance_users_reader" {
  scope                = data.azurerm_resource_group.finance_prod.id
  role_definition_name = "Reader"
  principal_id         = azuread_group.finance_users.object_id
}