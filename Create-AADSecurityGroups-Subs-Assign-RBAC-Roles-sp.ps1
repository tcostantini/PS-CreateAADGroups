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

$SubsNames = @(
  '<Subscription name 1>'
  '<Subscription name 2>'
)
$attempt = 0

do {
  $someAssignmentUnsuccessful = $false
  $attempt++
  
  Write-Host "Attempt: $attempt."
  $SecuredPassword2 = ConvertTo-SecureString -String $SecuredPassword -AsPlainText -Force
  $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ApplicationId, $SecuredPassword2

  Connect-AzAccount -ServicePrincipal -TenantId $TenantId -Credential $Credential
  Connect-AzureAD -TenantId $TenantId -Credential $Credential

  foreach ($SubsName in $SubsNames) {
	
    # Get subs id
    $subs = Get-AzSubscription -SubscriptionName $SubsName
  
    $adGroups = @{
      "owner"           = @{
        "name" = $SubsName + "-owner"
        "role" = "Owner"
      }
      "contributor"     = @{
        "name" = $SubsName + "-contributor"
        "role" = "Contributor"
      }
      "useraccessadmin" = @{
        "name" = $SubsName + "-useraccessadmin"
        "role" = "User Access Administrator"
      }
      "billingreader"   = @{
        "name" = $SubsName + "-billingreader"
        "role" = "Billing Reader"
      }
      "reader"          = @{
        "name" = $SubsName + "-reader"
        "role" = "Reader"
      }
    }
  
    Write-Host "Subscription Name : '$SubsName'"
  
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
      $subsId = $subs.Id

      Write-Host "Assigning RBAC Role to AzureAD Group: '$adGroupRole'."
      $roleResult = Get-AzRoleAssignment -ObjectId ($groupResult | ConvertFrom-Json).Id -RoleDefinitionName $adGroupRole -Scope "/subscriptions/$subsId"
      if (!$roleResult) {
        $roleResult = New-AzRoleAssignment -ObjectId ($groupResult | ConvertFrom-Json).Id -RoleDefinitionName $adGroupRole -ObjectType "Group" -Scope "/subscriptions/$subsId"
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