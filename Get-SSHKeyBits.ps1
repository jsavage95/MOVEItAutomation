<#
.SYNOPSIS

Retrieves the SSH key bit length of any public key.

.DESCRIPTION

The Get-SSHKeyBits function will return the key bit size of any public key passed to it (OpenSSH or SSH2 format).
This function accepts a single key path, as well as multiple pipelined inputs.
The function will convert an SSH2 formatted key to OpenSSH and save to a seperate file in the same directory.

.PARAMETER PublicKeyPath
Specifies the path to the public key(s).

.INPUTS

System.String[[]]


.EXAMPLE

"C:\temp\TestKey1.pub","C:\temp\TestKey2.pub" | Get-SSHKeyBits

.EXAMPLE

$keys | Get-SSHKeyBits

.EXAMPLE

Get-SSHKeyBits -PublicKeyPath C:\temp\testkey.pub

#>


Function Get-SSHKeyBits {

    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory, 
            ValueFromPipeline = $true)]
            [validatescript({
                Foreach-object {
                    if(!(test-path $_)){
                    $error[0]
                    break
                    }
                    else{
                        return $true
                    }
                }    
            })]
        [String[]]
        $PublicKeyPath,

        [parameter(Mandatory = $false)]
        [validatescript({
            if(!(test-path $_)){
                $error[0]
            }
            else{
                return $true
            }
        })]
        $ssh_KeygenPath = "C:\windows\system32\openssh\ssh-keygen.exe"
    )

    Begin{

        #Added validation of keygen path is required here for the default parameter set above.
        # The first validate script block for this parameter is required when there is user input.
        if(!(test-path $ssh_KeygenPath)){
            $error[0]
            break
        }

        #Declare empty results array for use in Foreach loop.
        $results = @()

        #This regex object helps place the key bits into its own custom property for the results array.
        [regex]$reg = "^\d{4}"
    }
 
    Process{
        Foreach ($key in $PublicKeyPath){

            Try{
                #Get the public key as an actual object, not just a string.
                $key = Get-ChildItem $key -ErrorAction Stop
            }
            Catch{
                $error[0]
                #If failed to retrieve object, move onto the next key.
                continue
            }
            
            #Check for SSH2 formatted keytype. If found, create new file with converted OpenSSH format in the same directory.
            if ((get-content $key) -match "ssh2"){
                Try{
                    
                    $content = Invoke-Expression -Command "$ssh_KeygenPath -i -f $($key.Fullname)"
                    
                    $key = New-Item -Path $key.directory.fullname -Name "$($key.basename)_OpenSSH$($key.extension)" -Value $content -ErrorAction Stop

                    Write-host "$($key.name) in SSH2 format. Converting to OpenSSH..." -ForegroundColor Yellow -BackgroundColor Black
                }
                Catch{
                    $error[0]
                    Continue
                }
            }

            Try{
                #Run the SSHKeyGen '-lf' command to get the details of the key.
                $SSHresults = Invoke-Expression -Command "$ssh_KeygenPath -lf $key"
            }
            Catch{
                $error[0].exception.message
                break
            }
            
            #This uses the $reg regex object to retrieve the amount of bits. Whatever match is found, is placed into the $matches.values variable
            #then used below in the hashtable.
            $SSHresults -match $reg | out-null

            $results += [pscustomobject]@{
                'Keyname' = $key.name
                'Bits' = $matches | select -expandproperty Values
                'AllKeyDetails' = $SSHresults
            }
        }
    }

    end{
        return $results | Sort-Object Bits
    }
}
