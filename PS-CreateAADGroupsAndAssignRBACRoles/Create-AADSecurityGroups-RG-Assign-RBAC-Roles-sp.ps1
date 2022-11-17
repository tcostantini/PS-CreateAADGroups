param
(
	[String]
	[Parameter(Mandatory)]
	$ApplicationId,

	[String]
	[Parameter(Mandatory)]
	$SecuredPassword,

	[String]
	[Parameter(Mandatory)]
	$TenantId
)

$rgNames = @{
	'<Subscription name 1>' = @(
		'<Resource group name 1>'
		'<Resource group name 2>'
	)
	'<Subscription name 2>' = @(
		'<Resource group name 1>'
		'<Resource group name 2>'
	)
}

$attempt = 0

$SecuredPassword2 = ConvertTo-SecureString -String $SecuredPassword -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ApplicationId, $SecuredPassword2

Connect-AzAccount -ServicePrincipal -TenantId $TenantId -Credential $Credential
Connect-AzureAD -TenantId $TenantId -Credential $Credential

do {
	$someAssignmentUnsuccessful = $false
	$attempt++
  
	Write-Host "Attempt: $attempt."

	foreach ($subsName in $rgNames.Keys) {
  	
		# Get subs id
		$subs = Get-AzSubscription -SubscriptionName $subsName
  	
		if (!$subs) {
			Write-Host "'$subsName' subscription not found. Script continuing."
		}
		else { 
			Write-Host "Found subscription $subsName, with id $subs.id"
		}  
  	
		Set-AzContext -Subscription $subs.id
  	
		Write-Host "Context set to the new subscription."
  	
		$rgList = $($rgNames.item($subsName))
    
		foreach ($resourceGroupName in $rgList) {
    
			$adGroups = @{
				"owner"           = @{
					"name" = $resourceGroupName + "-owner"
					"role" = "Owner"
				}
				"contributor"     = @{
					"name" = $resourceGroupName + "-contributor"
					"role" = "Contributor"
				}
				"useraccessadmin" = @{
					"name" = $resourceGroupName + "-useraccessadmin"
					"role" = "User Access Administrator"
				}
				"billingreader"   = @{
					"name" = $resourceGroupName + "-billingreader"
					"role" = "Billing Reader"
				}
				"reader"          = @{
					"name" = $resourceGroupName + "-reader"
					"role" = "Reader"
				}
			}
  	  
			Write-Host "Resource Group Name : '$resourceGroupName'"
  	  
			$rg = Get-AzResourceGroup -Name $resourceGroupName
			if (!$rg) {
				Write-Host "Resource Group does not exist. Script continuing."
			}
  	  
			# create groups
			foreach ($key in $adGroups.Keys) {
				$adGroupName = $($adGroups.item($key).name)
				$adGroupRole = $($adGroups.item($key).role)
			
				Write-Host "Creating AzureAD Group: '$adGroupName'."
			
				$groupResult = Get-AzADGroup -SearchString $adGroupName
				if (!$groupResult) {
					$groupResult = az ad group create --display-name $adGroupName --mail-nickname "NotSet"
				}
				else {
					Write-Host "'$adGroupName' already exists. Script continuing." 
				}
			
				# assign roles
				Write-Host "Assigning RBAC Role to AzureAD Group: '$adGroupRole'."
				$roleResult = Get-AzRoleAssignment -ResourceGroupName $resourceGroupName -ObjectId ($groupResult | ConvertFrom-Json).Id -RoleDefinitionName $adGroupRole 
				if (!$roleResult) {	
					$roleResult = New-AzRoleAssignment -ResourceGroupName $resourceGroupName -ObjectId ($groupResult | ConvertFrom-Json).Id -RoleDefinitionName $adGroupRole -ObjectType "Group"
					
					if (!$roleResult) {
						$someAssignmentUnsuccessful = $true
						Write-Host "Assignment unsuccessful."
					}
				}
				else {
					Write-Host "'$adGroupRole' already exists. Script continuing." 
				}  
			}
		}
	}
	
} while ($someAssignmentUnsuccessful)