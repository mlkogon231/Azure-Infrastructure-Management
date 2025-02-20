# scripts/security/compliance-check.ps1

param (
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName
)

# Connect to Azure (if not already connected)
Connect-AzAccount
Set-AzContext -Subscription $SubscriptionId

# Function to check RBAC assignments
function Get-RBACCompliance {
    param (
        [string]$ResourceGroupName
    )
    
    $rbacAssignments = Get-AzRoleAssignment -ResourceGroupName $ResourceGroupName
    $privilegedRoles = @("Owner", "Contributor")
    
    foreach ($assignment in $rbacAssignments) {
        if ($privilegedRoles -contains $assignment.RoleDefinitionName) {
            Write-Host "Warning: Privileged role '$($assignment.RoleDefinitionName)' assigned to '$($assignment.DisplayName)'"
        }
    }
}

# Function to check encryption settings
function Get-EncryptionCompliance {
    param (
        [string]$ResourceGroupName
    )
    
    # Check Storage Account encryption
    $storageAccounts = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName
    foreach ($sa in $storageAccounts) {
        if (-not $sa.Encryption.Services.Blob.Enabled) {
            Write-Host "Warning: Blob encryption not enabled for storage account '$($sa.StorageAccountName)'"
        }
    }
    
    # Check SQL Database encryption
    $sqlServers = Get-AzSqlServer -ResourceGroupName $ResourceGroupName
    foreach ($server in $sqlServers) {
        $databases = Get-AzSqlDatabase -ServerName $server.ServerName -ResourceGroupName $ResourceGroupName
        foreach ($db in $databases) {
            if (-not $db.TransparentDataEncryption.State -eq "Enabled") {
                Write-Host "Warning: TDE not enabled for database '$($db.DatabaseName)'"
            }
        }
    }
}

# Function to check network security
function Get-NetworkSecurityCompliance {
    param (
        [string]$ResourceGroupName
    )
    
    # Check NSG rules
    $nsgs = Get-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName
    foreach ($nsg in $nsgs) {
        $rules = $nsg.SecurityRules
        foreach ($rule in $rules) {
            if ($rule.Direction -eq "Inbound" -and $rule.SourceAddressPrefix -eq "*") {
                Write-Host "Warning: NSG '$($nsg.Name)' has rule allowing all inbound traffic"
            }
        }
    }
}

# Function to check compliance policies
function Get-PolicyCompliance {
    param (
        [string]$ResourceGroupName
    )
    
    $states = Get-AzPolicyState -ResourceGroupName $ResourceGroupName
    foreach ($state in $states) {
        if ($state.ComplianceState -eq "NonCompliant") {
            Write-Host "Non-compliant policy: '$($state.PolicyDefinitionName)' for resource '$($state.ResourceId)'"
        }
    }
}

# Execute compliance checks
Write-Host "=== Starting Compliance Check ==="
Write-Host "`nChecking RBAC Assignments..."
Get-RBACCompliance -ResourceGroupName $ResourceGroupName

Write-Host "`nChecking Encryption Settings..."
Get-EncryptionCompliance -ResourceGroupName $ResourceGroupName

Write-Host "`nChecking Network Security..."
Get-NetworkSecurityCompliance -ResourceGroupName $ResourceGroupName

Write-Host "`nChecking Policy Compliance..."
Get-PolicyCompliance -ResourceGroupName $ResourceGroupName

# Generate HTML report
$reportContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Azure Compliance Report</title>
    <style>
        body { font-family: Arial, sans-serif; }
        .warning { color: orange; }
        .error { color: red; }
    </style>
</head>
<body>
    <h1>Azure Compliance Report</h1>
    <h2>Resource Group: $ResourceGroupName</h2>
    <div id="results">
        <!-- Compliance results will be inserted here -->
    </div>
</body>
</html>
"@

$reportContent | Out-File "compliance-report.html"
Write-Host "`nCompliance report generated: compliance-report.html"