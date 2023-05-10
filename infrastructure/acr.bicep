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

// This is another portion to break out
// AKS DNS TEST
resource aksRG 'Microsoft.Resources/resourceGroups@2022-09-01' = {
	name: 'rg-aks-dns-test'
	location: location
}


module aksVnet 'br:tjsfdpo01.azurecr.io/bicep/modules/vnet:0.0.2' = {
	scope: aksRG
	name: 'aksvnet'
	params: {
		virtualNetworkName: 'vnet-aks-dns-t'
		addressPrefix: '10.1.0.0/16'
		subnets: [
		  {
				name: 'snet-aks'
				nsg_id: ''
				subnetPrefix: '10.1.0.0/24'
				PEpol: 'Enabled'
				PLSpol: 'Enabled'
				natgw_id: ''
			}	
		]
	}
}


module aks 'br:tjsfdpo01.azurecr.io/bicep/modules/aks:0.0.3' = {
	scope: aksRG
	name: 'aks-sample' 
	params: {
		acrName: acr.name
		dnsPrefix: 'aks-dns-t'
		dnsServiceIP: ''
		dockerBridgeCidr: ''
		networkPlugin: 'azure' 
		resourceName: 'aks-dns-t'
		serviceCidr: '172.0.0.0/24'
		vnetSubnetID: aksVnet.outputs.subnets[0].subnet_id
	}
}
