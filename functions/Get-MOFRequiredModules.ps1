function Get-MOFRequiredModules {
    [CmdletBinding()]
    Param(
        [ValidateNotNullOrEmpty()]
        [string]$MofFile= 'localhost.mof')

    $DSCResources = Get-DscResource
    $DSCModuleArray = @()
    $ModulesToCopy = @()

    foreach ($Resource in $DSCResources)
    {
        if (!(($Resource.ModuleName -eq "PSDesiredStateConfiguration") -or ($Resource.ImplementedAs -eq 'Binary')))
        {
            if ($DSCModuleArray -notcontains $Resource.ModuleName)
            {
                $DSCModuleArray += $Resource.ModuleName
            }
        }
    }

    #Scan the mof file for sections ModuleName
    $requiredModulesinMof = @()
    Switch -Regex (Get-Content $MofFile)
    {
        "ModuleName" {$requiredModulesInMof += $_.Split("`"")[1]}
    }

    foreach ($requiredModule in $requiredModulesInMof)
    {
        if ($requiredModule -in $DSCModuleArray)
        {
            $ModulesToCopy += [pscustomobject]@{
                        ModuleName = $requiredModule
                        }
        }
    }
    return $ModulesToCopy

}

function Copy-DSCResource
{
    [cmdletBinding()]
    Param($PSSession,$ModulestoCopy)
    
    foreach ($Module in $ModulestoCopy)
    {
        $Source = 'C:\Program Files\WindowsPowerShell\Modules\'+$Module.ModuleName
        $Destination = 'C:\Program Files\WindowsPowerShell\Modules\'
        try
        {
            Copy-Item -ToSession $PSSession -Path $Source -Destination $Destination -Recurse -Force -ErrorAction STOP -Verbose
        }
        catch
        {
            Write-Output $Error[0].Exception
            break
        }
    }

}


