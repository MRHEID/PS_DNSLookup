PARAM (
    [Parameter(mandatory=$True,position=1)]
    [string] $InputList, #Looking for a list.  when calling script make sure this is an array and not a text input
    [Parameter(mandatory=$True,position=2)]
    [string] $OutputFile #name of CSV Output File
)

<###  Output File Name  ###>
$OutputFileName = $OutputFile + $(get-date -format filedatetime) + ".csv"

<###  Define Output Array  ###>
$output =@()

<###  Loop through list  ###>
Foreach ($item in $InputList){
    
    remove-variable Result | Out-Null  #Clear Variable from last run
    
    IF ($item -match '^\d+\.\d+\.\d+\.\d+'){  # Regex looking for IP pattern
        Write-Host "Forward Lookup: $item"
        $result = [system.net.dns]::GetHostByAddress($item) # NSLookup using .net on IP
    }
    
    Else {
        Write-Host "Reverse Lookup: $Item"
        $Result = [system.net.dns]::GetHostByName($item) # Nslookup using .net on hostname
        if($Null -eq $Result){  # So if the above fails and the $Result is null.  Put some useful troubleshooting info in the output.
            $Result = New-Object PSObject -property @{
                Hostname = $item
                AddressList = "ERROR"
                Aliases = "ERROR"
            }
        }
    }
    <###  If there's multiple IPs in the address list this will make it a single string  ###>
    $PTRList = $NULL  #Null the string
    foreach ($PTR in $Result.AddressList){ #loop throught he reverse_ptr list
        if($NULL -eq $PTRList){ # if this is the first one, add the address without the ;
            $PTRList = $PTR
        }
        Else { # append additional addresses to $PTR with a ; between
            $PTRList = $PTRList + ";" + $PTR
        }
    }
    
    <###  Append results to the $output Object  ###>   
    $output += New-Object PSObject -property @{
        Reverse_PTR = $PTRList
        A_Record = $Result.HostName
        CNAME_Record = $Result.Aliases 
    }
}

$Output | Export-Csv $OutputFileName -NoTypeInformation -noclobber
