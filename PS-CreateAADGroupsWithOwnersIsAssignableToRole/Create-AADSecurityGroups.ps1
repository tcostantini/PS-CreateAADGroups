$tenantId = '00000000-0000-0000-0000-000000000000'

$owners = @(
  'user1@yourdomain.onmicrosoft.com'
  'user2@yourdomain.onmicrosoft.com'
  'user3@yourdomain.onmicrosoft.com'
)

$adGroups = @{
  "GroupName1" = @{
    "isAssignableToRole" = $false
  }
  "GroupName2" = @{
    "isAssignableToRole" = $false
  }  
  "GroupName3" = @{
    "isAssignableToRole" = $true
  } 
}

az login --tenant $tenantId

Connect-AzureAD -TenantId $tenantId

foreach ($key in $adGroups.Keys) {
  $adGroupName        = $key
  $isAssignableToRole = $($adGroups.item($key).isAssignableToRole)
  
  Write-Host "Creating AzureAD Group: '$adGroupName'"
  
  $adGroup = Get-AzADGroup -SearchString $adGroupName
  
  if (!$adGroup) {
    $adGroup = New-AzureADMSGroup -DisplayName $adGroupName -MailEnabled $False -MailNickname "NotSet" -SecurityEnabled $True -IsAssignableToRole $isAssignableToRole
  }
  else {
    "'$adGroupName' already exists. Script continuing." 
  }
  
  Write-Host "Assigning owners to AzureAD Group: '$adGroupName'"
  
  foreach ($owner in $owners) {
    $adUser = Get-AzureADUser -ObjectId $owner
  
    Write-Host "Assigning owner: '$owner'"
    
    $adGroupOwners = Get-AzureADGroupOwner -ObjectId $adGroup.Id -All $true	  
    $adGroupOwner = $adGroupOwners -Match $adUser.ObjectId
    
    if (!$adGroupOwner) {
      $adGroupOwner = Add-AzureADGroupOwner -ObjectId $adGroup.Id -RefObjectId $adUser.ObjectId
    }
    else {
      "'$owner' is already an owner. Script continuing." 
    }
  }
}