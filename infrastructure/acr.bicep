targetScope = 'subscription'

@description('Friendly name for resousource group')
param resourceGroupName string

@description('Location for all resources.')
param location string

@minLength(5)
@maxLength(50)
@description('Name of the azure container registry (must be globally unique)')
param acrName string

@description('Enable an admin user that has push/pull permission to the registry.')
param acrAdminUserEnabled bool = false

@allowed([
  'Basic'
  'Standard'
  'Premium'
])
@description('Tier of your Azure Container Registry.')
param acrSku string = 'Basic'

@description('Key/Value pairs for the Azure Metasdata')
param tags object = {}

resource acrRG 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: resourceGroupName
  location: location
}

module acr 'br:tjsfdpo01.azurecr.io/bicep/modules/acr:0.0.1' = {
  name: 'acrDeployment'
	scope: acrRG
	params: {
		acrSku: acrSku
	  acrName: acrName
	  acrAdminUserEnabled: acrAdminUserEnabled
	  location: location
		submitted_tags: tags
	}
}

// This is a section that should be broken out, but will tempaorarily be a holder for me to use the existing SPs
resource mtWFunctionRG 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: 'rg-multitenant-function-sample'
  location: location
}

module aca1 'br:tjsfdpo01.azurecr.io/bicep/modules/containerapp:0.0.1' = {
	name: 'aca1'
	scope: mtWFunctionRG
	params: {
		 containerAppEnvName: 'came-fdpo-01'
		 containerAppName: 'ca-fdpo-01'
	}
}

module aca2 'br:tjsfdpo01.azurecr.io/bicep/modules/containerapp:0.0.1' = {
	name: 'aca2'
	scope: mtWFunctionRG
	params: {
		 containerAppEnvName: 'came-fdpo-02'
		 containerAppName: 'ca-fdpo-02'
	}
}
