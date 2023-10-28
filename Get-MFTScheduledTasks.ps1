#Returns a list of enabled tasks in MOVEit automation

function Get-MFTScheduledTasks {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string]
        $MIAServer = "MIASERVERNAME",

        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSCredential]
        $Credential = (Get-credential)
    )

    #check for module
    if (!(Get-Module -Name MOVEit.MIA -ListAvailable)){
        Return "MOVEit.MIA Module not installed. Please install first before running command"
        break
    }

    Try{
        Connect-MIAServer -Hostname $MIAServer -Credential $cred
    }
    Catch{
        $error[0]
        break
    }


    $enabled_tasks = Get-MIATask | Where-Object {$_.scheduled -eq "Enabled"} 


    $enabled_tasks | Add-Member -MemberType NoteProperty -Name "Days" -Value ""
    $enabled_tasks | Add-Member -MemberType NoteProperty -Name "StartTime" -Value ""
    $enabled_tasks | Add-Member -MemberType NoteProperty -Name "EndTime" -Value ""
    $enabled_tasks | Add-Member -MemberType NoteProperty -Name "EveryMinutes" -Value ""

    foreach ($task in $enabled_tasks)
    {
        $task.days += $task.schedules.schedule.days.dayofweek
        $task.starttime += $task.Schedules.schedule.frequency.interval.starttime
        $task.endtime += $task.Schedules.schedule.frequency.interval.endtime
        $task.everyminutes += $task.Schedules.schedule.frequency.interval.everyminutes
        
    }

    #$enabled_tasks | Select-Object name, days, starttime, endtime, everyminutes | Sort-Object starttime | Format-Table
    $enabled_tasks | Select-Object name, days, starttime, endtime, everyminutes | Sort-Object starttime 

}
