Function Send-SFTPFiles{

    [[CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $LocalPath = $miaclient.MIGetTaskParam("TO BE DETERMINED"),
  
        [Parameter(Mandatory)]
        [string]
        $remoteOutPath = $miaclient.MIGetTaskParam("TO BE DETERMINED"),
  
        [Parameter(Mandatory)]
        [ValidateScript({
          if ($filename -notmatch ".zip"){
            $miaclient.MISetErrorCode(1)
            $miaclient.MISetErrorDescription("$($filename) not zipped and password protected")
            $miaclient.MILogMsg("$error[0]")
            exit
          }
        })]
        [string]
        $filename = $miaclient.MIGetTaskParam("TO BE DETERMINED")
    )]
    
  
    $ErrorActionPreference = Stop
    Try{
      Add-Type -Path (Join-Path $env:WINSCP_PATH "WinSCPnet.dll")
    }
    Catch{
      $miaclient.MISetErrorCode(1)
      $miaclient.MISetErrorDescription($error[0])
      $miaclient.MILogMsg("$error[0]")
      exit
    }
    
    #Set Session option variables
    $SSHHostName = "sftphosttest.com" 
    $SSHUserName = "sftp-user"
    $SshPrivateKeyPath = "C:\path\to\privatekey.ppk"
    $Port = "22"
  
    #Change to PrivateKeyPhrase.txt once completed testing. This is encrypted with the mft account
    Try{
      #This imports and decrypts the private key passphrase used for the SSH key. This has been created with the svc_mft_pro account and will only work under this account.
      $PrivateKeyPhrase = Get-Content C:\path\to\PrivateKeyPhrase.txt | ConvertTo-SecureString
    }
    Catch{
      $miaclient.MISetErrorCode(1)
      $miaclient.MISetErrorDescription($error[0])
      $miaclient.MILogMsg("$error[0]")
      exit
    }
    
  
    $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
        Protocol = [WinSCP.Protocol]::Sftp
        HostName = $SSHHostName
        UserName = $SSHUserName
        PortNumber = $Port
        SshPrivateKeyPath = $SshPrivateKeyPath
        SecurePrivateKeyPassphrase = $PrivateKeyPhrase
        SshHostKeyFingerprint = "enter fingerprint"
    }
  
  
    try {
  
        $session = New-Object WinSCP.Session
        # Open logging
        $session.SessionLogPath = "C:\temp\transferlog-$(Get-Date -UFormat %Y-%m-%d-%H).log"
  
        # Connect
        $session.Open($sessionOptions)
        
        $transferOptions = New-Object WinSCP.TransferOptions
        $transferOptions.ResumeSupport.State = [WinSCP.TransferResumeSupportState]::Off
        
        # Upload files, collect results
        #Documentation https://winscp.net/eng/docs/library_session_putfilestodirectory#parameters
  
        $transferResult = $session.PutFilesToDirectory($LocalPath, $remoteOutPath,$filename,$false, $transferOptions)
  
        # Check if there was a global failure for upload
        if (!($transferResult.IsSuccess)){
          #log the transfer result error message into MOVEit failure codes.
          $miaclient.MISetErrorDescription($transferResult.failures)
          $miaclient.MILogMsg($transferResult.failures)
          $miaclient.MISetErrorCode(1)
          exit
        }
        else{
          $miaclient.MILogMsg("Transfer of $($filename) successful! to $($remoteOutPath)")
          #Set custom task paramater in order for MOVEit task to archive files.
          $miaclient.MISetTaskParam("TransferSuccessful", "True")
        }
        
    }
    Catch{
      $miaclient.MISetErrorCode(1)
      $miaclient.MISetErrorDescription($error[0])
      $miaclient.MILogMsg("$error[0]")
      exit
    }
  
  }
  