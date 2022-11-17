$MGNames = @(
  '<Management group name 1>'	
  '<Management group name 2>'	
)
$attempt = 0

do {
  $someAssignmentUnsuccessful = $false
  $attempt++
  
  Write-Host "Attempt: $attempt."
	
  foreach ($MGName in $MGNames) {
    $adGroups = @{
      "owner"           = @{
        "name" = $MGName + "-owner"
        "role" = "Owner"
      }
      "contributor"     = @{
        "name" = $MGName + "-contributor"
        "role" = "Contributor"
      }
      "useraccessadmin" = @{
        "name" = $MGName + "-useraccessadmin"
        "role" = "User Access Administrator"
      }
      "billingreader"   = @{
        "name" = $MGName + "-billingreader"
        "role" = "Billing Reader"
      }
      "reader"          = @{
        "name" = $MGName + "-reader"
        "role" = "Reader"
      }
    }
  
    Write-Host "Management Group Name : '$MGName'"
  
    foreach ($key in $adGroups.Keys) {
      $adGroupName = $($adGroups.item($key).name)
      $adGroupRole = $($adGroups.item($key).role)
	
      Write-Host "Creating AzureAD Group: '$adGroupName'"
	
      $groupResult = Get-AzADGroup -SearchString $adGroupName
      if (!$groupResult) {
        $groupResult = az ad group create --display-name $adGroupName --mail-nickname "NotSet"
      }
      else {
        "'$adGroupName' already exists. Script continuing." 
      }
	
      # assign roles
      Write-Host "Assigning RBAC Role to AzureAD Group: '$adGroupRole'."
      $roleResult = Get-AzRoleAssignment -ObjectId ($groupResult | ConvertFrom-Json).Id -RoleDefinitionName $adGroupRole -Scope /providers/Microsoft.Management/managementGroups/$MGName
	
      if (!$roleResult) {
        $roleResult = New-AzRoleAssignment -ObjectId ($groupResult | ConvertFrom-Json).Id -RoleDefinitionName $adGroupRole -ObjectType "Group" -Scope /providers/Microsoft.Management/managementGroups/$MGName

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
	
} while ($someAssignmentUnsuccessful)