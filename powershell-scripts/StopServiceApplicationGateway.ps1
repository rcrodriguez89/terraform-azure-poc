# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave –Scope Process
 
# Obteniendo conexion 
$Conn = Get-AutomationConnection -Name AzureRunAsConnection
Connect-AzAccount -ServicePrincipal -Tenant $Conn.TenantID -ApplicationId $Conn.ApplicationID -CertificateThumbprint $Conn.CertificateThumbprint
$AzureContext = Select-AzSubscription -SubscriptionId $Conn.SubscriptionID
 
# Obteniendo instancia de Application Gateway
$AppGw=Get-AzApplicationGateway -Name "NekoAppGateway" -ResourceGroupName "NekoResourceGroup"
 
# Deteniendo instancia de Application Gateway
Stop-AzApplicationGateway -ApplicationGateway $AppGw