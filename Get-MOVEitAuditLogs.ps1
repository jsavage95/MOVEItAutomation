<#
.SYNOPSIS
    Retrieves logs from the Audit table on the MOVEit Database.
.DESCRIPTION
    Built to retrieve audit logs and export to a storage location for auditing and compliance.
    Runs directly from the MOVEit server.
.NOTES
    Needs to be passed an existing connection object. 
.EXAMPLE
    $connection = Connect-SQLDB -SQLServer "sqlservername" -DatabaseName "moveitautomation"

    Get-MOVEitAuditLogs -SQLConnectionObject $connection
#>

Function Get-MOVEitAuditLogs{

    param(
        [Parameter(Mandatory)]
        [System.Data.SqlClient.SqlConnection]$SQLConnectionObject
    )

    #Get the current and previous month into a datetime object, then use this to get all logs of the previous month.
    $currentDate = Get-Date -Format yyyy-MM-dd
    $PreviousMonth = (Get-Date -Date $currentDate).addMonths(-1)

    #Need to change format after using the addMonths method, otherwise the -Format parameter converts it to a string object and the method is no longer available.
    $PreviousMonth = get-date -Date $PreviousMonth -Format yyyy-MM-dd


    $query = "SELECT LogTime, Action, TargetName, TargetType, Username, ClientIP, IPAddress, Error, ErrorText, Message, AgentBrand, TargetID
        from [audit] WHERE LogTime > '$PreviousMonth' AND LogTime <= '$currentDate' ORDER BY LogTime desc"


    #Create sql command for querying the DB.
    $command = $SQLConnectionObject.CreateCommand()
    $command.CommandText = $query
    
    $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataSet) | Out-Null

    $MOVEitAuditLogs = $dataset.Tables

    $SQLConnectionObject.close()

    return $MOVEitAuditLogs
}