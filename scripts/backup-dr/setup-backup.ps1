# scripts/backup-dr/setup-backup.ps1

# Connect to Azure (if not already connected)
Connect-AzAccount

# Parameters
$resourceGroupName = "rg-demo-dev"
$vaultName = "rsv-demo-dev"
$webAppName = "app-demo-dev"
$sqlServerName = "sql-demo-dev"
$sqlDatabaseName = "sqldb-demo-dev"

# Create Recovery Services Vault
$vault = New-AzRecoveryServicesVault `
    -ResourceGroupName $resourceGroupName `
    -Name $vaultName `
    -Location "eastus"

# Set vault context
Set-AzRecoveryServicesVaultContext -Vault $vault

# Configure backup policy
$backupPolicy = New-AzRecoveryServicesBackupProtectionPolicy `
    -Name "DailyPolicy" `
    -WorkloadType "AzureVM" `
    -RetentionDailyCount 7

# Enable SQL Database long-term retention
Set-AzSqlDatabaseBackupLongTermRetentionPolicy `
    -ResourceGroupName $resourceGroupName `
    -ServerName $sqlServerName `
    -DatabaseName $sqlDatabaseName `
    -WeeklyRetention "P4W" `
    -MonthlyRetention "P12M" `
    -YearlyRetention "P5Y" `
    -WeekOfYear 1

# Configure geo-replication for SQL Database
$primaryDatabase = Get-AzSqlDatabase `
    -ResourceGroupName $resourceGroupName `
    -ServerName $sqlServerName `
    -DatabaseName $sqlDatabaseName

$secondaryServerName = "sql-demo-dev-secondary"
$secondaryResourceGroupName = "rg-demo-dev-secondary"

# Create secondary server in a different region
New-AzSqlServer `
    -ResourceGroupName $secondaryResourceGroupName `
    -ServerName $secondaryServerName `
    -Location "westus" `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $sqlAdminUsername, $(ConvertTo-SecureString -String $sqlAdminPassword -AsPlainText -Force))

# Configure geo-replication
$primaryDatabase | New-AzSqlDatabaseSecondary `
    -PartnerResourceGroupName $secondaryResourceGroupName `
    -PartnerServerName $secondaryServerName `
    -AllowConnections "All"

# Output configuration status
Write-Host "Backup and DR configuration completed:"
Write-Host "- Recovery Services Vault: $vaultName"
Write-Host "- Backup Policy: DailyPolicy"
Write-Host "- SQL Database LTR: Configured"
Write-Host "- Geo-replication: Configured with secondary in westus"