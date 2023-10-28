

# Load WinSCP .NET Assembly
Add-Type -Path "C:\Program Files (x86)\WinSCP\WinSCPnet.dll"


Function Get-PrivateKeyPassphrase {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({
            if(!(Test-Path $_)){
                $miaclient.MISetErrorCode(1)
                $miaclient.MISetErrorDescription("Cannot find private key passphrase file at $($_)")
                $miaclient.MILogMsg($_)
                exit
              }
              else{
                  return $True
              } 
            })]
        [String]$PrivateKeyPassphraseLocation
    )

    Try{
        $Password = Get-Content $PrivateKeyPassphraseLocation | ConvertTo-SecureString

    }Catch{
        $miaclient.MISetErrorCode(1)
        $miaclient.MISetErrorDescription($error[0])
        $miaclient.MILogMsg("$error[0]")
        exit
    }

    return $Password
}


# Function to download files from SFTP server
function Get-SFTPFiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$SftpHost,

        [Parameter(Mandatory=$true)]
        [string]$SftpUsername,

        [Parameter(Mandatory=$true)]
        [string]$Port,

        [Parameter(Mandatory=$true)]
        [string]$PrivateKeyFilePath,

        [Parameter(Mandatory=$true)]
        [SecureString]$PrivateKeyPassphrase,

        [Parameter(Mandatory=$true)]
        [String]$SSHHostKeyFingerprint,

        [Parameter()]
        [string]$RemotePath = $miaclient.MIGetTaskParam("RemotePath"),

        [Parameter()]
        [string]$LocalPath = $miaclient.MIGetTaskParam("Localpath"),

        [Parameter()]
        [string]$Filemask = $miaclient.MIGetTaskParam("Filemask")
    )
    

    # Set up session options
    $sessionOptions = New-Object WinSCP.SessionOptions
    $sessionOptions.Protocol = [WinSCP.Protocol]::Sftp
    $sessionOptions.HostName = $SftpHost
    $sessionOptions.PortNumber = $Port
    $sessionOptions.UserName = $SftpUsername
    $sessionOptions.SshPrivateKeyPath = $PrivateKeyFilePath
    $sessionOptions.SecurePrivateKeyPassphrase = $PrivateKeyPassphrase
    $sessionOptions.SshHostKeyFingerprint = $SSHHostKeyFingerprint
    
    # Set up session
    $session = New-Object WinSCP.Session
    $session.Open($sessionOptions)
    
    try {
            # Set up transfer options
            $transferOptions = New-Object WinSCP.TransferOptions
            #$transferOptions.TransferMode = [WinSCP.TransferMode]::Binary
            
            # Download files. $True refers to whether or not to remove files after download.
            $transferResult = $session.GetFilesToDirectory($RemotePath, $LocalPath, $Filemask ,$false, $transferOptions)
            
            # Check for errors
            if (($transferResult.IsSuccess) -and ($transferResult.transfers.count -gt 0)) {
                #Set custom task paramater in order for MOVEit task to archive files.
                $miaclient.MISetTaskParam("TransferSuccessful", "True")

                Foreach($file in $transferResult.Transfers.filename){
                    $name = $file -replace '.*/([^/]+)$', '$1'
                    $miaclient.MILogMsg("Successfully downloaded '$name' from '$RemotePath'")
                }
            }
            elseif(!($transferResult.transfers)){
                $miaclient.MISetTaskParam("NoTransfers", "True")
                $miaclient.MILogMsg("WARNING: No files found to download!")
            }
            else {
                $miaclient.MISetErrorDescription($transferResult.failures)
                $miaclient.MILogMsg($transferResult.failures)
                $miaclient.MISetErrorCode(1)
                $miaclient.MISetTaskParam("TransferFailed", "True")
                exit
            }

    }
    Catch{
        $miaclient.MISetErrorCode(1)
        $miaclient.MISetErrorDescription($error[0])
        $miaclient.MILogMsg("$error[0]")
        exit
    }
    finally {
        # Close session
        $session.Dispose()
        Stop-Transcript
    }
}

$Password = Get-PrivateKeyPassphrase -PrivateKeyPassphraseLocation "C:\path\to\file"

Get-SFTPFiles -SftpHost "hostname.com" -SftpUsername "sftp-user" -Port "22" -PrivateKeyFilePath "C:\path\to\file\sftptest.ppk" -PrivateKeyPassphrase $Password -SSHHostKeyFingerprint "ssh key fingerprint"
