function Invoke-CommandAs {

<#

.SYNOPSIS

    Invoke Command as System/User on Local/Remote computer using ScheduleTask.

.DESCRIPTION

    Invoke Command as System/User on Local/Remote computer using ScheduleTask.
    ScheduledJob will be executed with current user credentials if no -As <credential> or -AsSystem is provided.

    Using ScheduledJob as they are ran in the background and the output can be retreived by any other process.
    Using ScheduledTask to Run the ScheduledJob, since you can allow Tasks to run as System or provide any credentials.
    
    Because the ScheduledJob is executed by the Task Scheduler, it is invoked locally as a seperate process and not from within the current Powershell Session.
    Resolving the Double Hop limitations by Powershell Remote Sessions. 

    By Marc R Kellerman (@mkellerman)

.PARAMETER ComputerName

    Specifies the computers on which the command runs. The default is the local computer.
        
    When you use the ComputerName parameter, Windows PowerShell creates a temporary connection that is used only to run the specified command and is then closed. If you need a persistent connection, use the Session parameter.
        
    Type the NETBIOS name, IP address, or fully qualified domain name of one or more computers in a comma-separated list. To specify the local computer, type the computer name, localhost, or a dot (.).
        
    To use an IP address in the value of ComputerName , the command must include the Credential parameter. Also, the computer must be configured for HTTPS transport or the IP address of the remote computer must be included in the WinRM TrustedHosts 
    list on the local computer. For instructions for adding a computer name to the TrustedHosts list, see "How to Add a Computer to the Trusted Host List" in about_Remote_Troubleshooting.
        
    On Windows Vista and later versions of the Windows operating system, to include the local computer in the value of ComputerName , you must open Windows PowerShell by using the Run as administrator option.
        
.PARAMETER Credential

    Specifies a user account that has permission to perform this action. The default is the current user.
        
    Type a user name, such as User01 or Domain01\User01. Or, enter a PSCredential object, such as one generated by the Get-Credential cmdlet. If you type a user name, this cmdlet prompts you for a password.
        
.PARAMETER Session

    Specifies an array of sessions in which this cmdlet runs the command. Enter a variable that contains PSSession objects or a command that creates or gets the PSSession objects, such as a New-PSSession or Get-PSSession command.
        
    When you create a PSSession , Windows PowerShell establishes a persistent connection to the remote computer. Use a PSSession to run a series of related commands that share data. To run a single command or a series of unrelated commands, use the 
    ComputerName parameter. For more information, see about_PSSessions.
        
.PARAMETER ScriptBlock

    Specifies the commands to run. Enclose the commands in braces ( { } ) to create a script block. This parameter is required.
        
    By default, any variables in the command are evaluated on the remote computer. To include local variables in the command, use ArgumentList .
        
.PARAMETER ArgumentList

    Supplies the values of local variables in the command. The variables in the command are replaced by these values before the command is run on the remote computer. Enter the values in a comma-separated list. Values are associated with variables in 
    the order that they are listed. The alias for ArgumentList is Args.
        
    The values in the ArgumentList parameter can be actual values, such as 1024, or they can be references to local variables, such as $max.
        
    To use local variables in a command, use the following command format:
        
    `{param($<name1>[, $<name2>]...) <command-with-local-variables>} -ArgumentList <value> -or- <local-variable>`
        
    The param keyword lists the local variables that are used in the command. ArgumentList supplies the values of the variables, in the order that they are listed.
        
.PARAMETER As

    ScheduledJob will be executed using this user. Specifies a user account that has permission to perform this action. The default is the current user.
        
    Type a user name, such as User01 or Domain01\User01. Or, enter a PSCredential object, such as one generated by the Get-Credential cmdlet. If you type a user name, this cmdlet prompts you for a password.
        
.PARAMETER AsSystem

    ScheduledJob will be executed using 'NT AUTHORITY\SYSTEM'. 

.PARAMETER AsGMSA

    ScheduledJob will be executed as the specified GMSA. For Example, 'domain\gmsa$'
        
.PARAMETER RunElevated

    Runs the ScheduledTask with the permissions of a member of the Administrators group on the computer on which the job runs.

.PARAMETER AsJob

    Indicates that this cmdlet runs the command as a background job on a remote computer. Use this parameter to run commands that take an extensive time to finish.
        
    When you use the AsJob parameter, the command returns an object that represents the job, and then displays the command prompt. You can continue to work in the session while the job finishes. To manage the job, use the Job cmdlets. To get the job 
    results, use the Receive-Job cmdlet.
        
    The AsJob parameter resembles using the Invoke-Command cmdlet to run a Start-Job command remotely. However, with AsJob , the job is created on the local computer, even though the job runs on a remote computer, and the results of the remote job are 
    automatically returned to the local computer.
        
    For more information about Windows PowerShell background jobs, see about_Jobs (http://go.microsoft.com/fwlink/?LinkID=113251) and about_Remote_Jobs (http://go.microsoft.com/fwlink/?LinkID=135184).
        
.PARAMETER JobName

    Specifies a friendly name for the background job. By default, jobs are named Job<n>, where <n> is an ordinal number.
        
    If you use the JobName parameter in a command, the command is run as a job, and Invoke-Command returns a job object, even if you do not include AsJob in the command.
        
    For more information about Windows PowerShell background jobs, see about_Jobs (http://go.microsoft.com/fwlink/?LinkID=113251).
        
.PARAMETER ThrottleLimit

    Specifies the maximum number of concurrent connections that can be established to run this command. If you omit this parameter or enter a value of 0, the default value, 32, is used.
        
    The throttle limit applies only to the current command, not to the session or to the computer.
        
#>

    [cmdletbinding(DefaultParameterSetName="None")]
    Param(
    
        [Parameter(Mandatory = $false, ParameterSetName = 'ComputerName', Position=0)]
        [string[]]$ComputerName,
    
        [Parameter(Mandatory = $false, ParameterSetName = 'ComputerName')]
        [System.Management.Automation.PSCredential]$Credential,
    
        [Parameter(Mandatory = $false, ParameterSetName = 'PSSession', Position=0)]
        [System.Management.Automation.Runspaces.PSSession[]]$Session,
    
        [Parameter(Mandatory = $true,  Position=1)]
        [ScriptBlock]$ScriptBlock,
    
        [Parameter(Mandatory = $false)]
        [Object[]]$ArgumentList,
    
        [System.Management.Automation.PSCredential]$As,
    
        [Parameter(Mandatory = $false)]
        [Switch]$AsSystem,

        [Parameter(Mandatory = $false)]
        [String]$AsGMSA,
    
        [Parameter(Mandatory = $false)]
        [Switch]$RunElevated,
    
        [Parameter(Mandatory = $false, ParameterSetName = 'ComputerName')]
        [Parameter(Mandatory = $false, ParameterSetName = 'PSSession')]
        [Switch]$AsJob,
    
        [Parameter(Mandatory = $false, ParameterSetName = 'ComputerName')]
        [Parameter(Mandatory = $false, ParameterSetName = 'PSSession')]
        [String]$JobName,
    
        [Parameter(Mandatory = $false, ParameterSetName = 'ComputerName')]
        [Parameter(Mandatory = $false, ParameterSetName = 'PSSession')]
        [Int]$ThrottleLimit
    
    )


    function Invoke-ScheduledTask {

        #Requires -Version 3
        
        [cmdletbinding()]
        Param(
        [Parameter(Mandatory = $true)][ScriptBlock]$ScriptBlock,
        [Parameter(Mandatory = $false)][Object[]]$ArgumentList,
        [Parameter(Mandatory = $false)][PSCredential]$Credential,
        [Parameter(Mandatory = $false)][Switch]$AsSystem,
        [Parameter(Mandatory = $false)][String]$AsGMSA,
        [Parameter(Mandatory = $false)][Switch]$RunElevated

        )

        Begin { 
        
            $JobName = [guid]::NewGuid().Guid 

        }
    
        Process {
        
            Try {

                $JobName = [guid]::NewGuid().guid

                Write-Verbose "Register-ScheduledJob: $JobName"
                $JobParameters = @{ }
                If ($ScriptBlock)  { $JobParameters['ScriptBlock']  = $ScriptBlock }
                If ($ArgumentList) { $JobParameters['ArgumentList'] = $ArgumentList }
                If ($Credential)   { $JobParameters['Credential'] = $Credential }
                If ($RunElevated)  { $JobParameters['ScheduledJobOption'] = New-ScheduledJobOption -RunElevated }

                # Little bit of inception to get $Using variables to work.
                # Collect $Using:variables, Rename and set new variables inside the job.

                # Inspired by Boe Prox, and his https://github.com/proxb/PoshRSJob module
                #      and by Warren Framem and his https://github.com/RamblingCookieMonster/Invoke-Parallel module

                $JobParameters['Using'] = @()
                $UsingVariables = $ScriptBlock.ast.FindAll({$args[0] -is [System.Management.Automation.Language.UsingExpressionAst]},$True)
                If ($UsingVariables) {

                    $ScriptText = $ScriptBlock.Ast.Extent.Text
                    $ScriptOffSet = $ScriptBlock.Ast.Extent.StartOffset
                    ForEach ($SubExpression in ($UsingVariables.SubExpression | Sort { $_.Extent.StartOffset } -Descending)) {

                        $Name = '__using_{0}' -f (([Guid]::NewGuid().guid) -Replace '-')
                        $Expression = $SubExpression.Extent.Text.Replace('$Using:','$').Replace('${Using:','${'); 
                        $Value = [System.Management.Automation.PSSerializer]::Serialize((Invoke-Expression $Expression))
                        $JobParameters['Using'] += [PSCustomObject]@{ Name = $Name; Value = $Value } 
                        $ScriptText = $ScriptText.Substring(0, ($SubExpression.Extent.StartOffSet - $ScriptOffSet)) + "`${Using:$Name}" + $ScriptText.Substring(($SubExpression.Extent.EndOffset - $ScriptOffSet))

                    }
                    $JobParameters['ScriptBlock'] = Invoke-Expression $ScriptText
                }

                $JobScriptBlock = [ScriptBlock]::Create(@"

                    Param(`$Parameters)

                    `$JobParameters = @{}
                    If (`$Parameters.ScriptBlock)  { `$JobParameters['ScriptBlock']  = [ScriptBlock]::Create(`$Parameters.ScriptBlock) }
                    If (`$Parameters.ArgumentList) { `$JobParameters['ArgumentList'] = `$Parameters.ArgumentList }
    
                    If (`$Parameters.Using) { 
                        `$Parameters.Using | % { Set-Variable -Name `$_.Name -Value ([System.Management.Automation.PSSerializer]::Deserialize(`$_.Value)) }
                        Start-Job @JobParameters | Receive-Job -Wait -AutoRemoveJob
                    } Else {
                        Invoke-Command @JobParameters
                    }

"@)

                $ScheduledJob = Register-ScheduledJob -Name $JobName -ScriptBlock $JobScriptBlock -ArgumentList $JobParameters -ErrorAction Stop

                If (($AsSystem) -or ($AsGMSA)) {

                    # Use ScheduledTask to execute the ScheduledJob to execute with the desired credentials.

                    Write-Verbose "Register-ScheduledTask"
                    $TaskParameters = @{ TaskName = $JobName }
                    $TaskParameters['Action'] = New-ScheduledTaskAction -Execute $ScheduledJob.PSExecutionPath -Argument $ScheduledJob.PSExecutionArgs
                    $RunLevel = If ($RunElevated) { 'Highest' } Else { 'Limited' }
                    If ($AsSystem) {
                        $TaskParameters['Principal'] = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel $RunLevel
                    } ElseIf ($AsGMSA) {
                        $TaskParameters['Principal'] = New-ScheduledTaskPrincipal -UserID $AsGMSA -LogonType Password -RunLevel $RunLevel
                    }
                    $ScheduledTask = Register-ScheduledTask @TaskParameters -ErrorAction Stop

                    Write-Verbose "Start-ScheduledTask"
                    $CimJob = $ScheduledTask | Start-ScheduledTask -AsJob -ErrorAction Stop
                    $CimJob | Wait-Job | Remove-Job -Force -Confirm:$False

                    Write-Verbose "Get-ScheduledJob"
                    While (-Not($Job = Get-Job -Name $ScheduledJob.Name -ErrorAction SilentlyContinue)) { Start-Sleep -Milliseconds 200 }

                    Write-Verbose "Receive-ScheduledJob"
                    $Job | Wait-Job | Receive-Job -Wait -AutoRemoveJob

                } Else {

                    # It no other credentials where provided, execute the ScheduledJob as is.
                    Write-Verbose "Start-ScheduledTask"
                    $Job = $ScheduledJob.StartJob()

                    Write-Verbose "Receive-ScheduledJob"
                    $Job  | Receive-Job -Wait -AutoRemoveJob
    
                }

            } Catch { Throw $_ }

        }

        End {

            If ($ScheduledTask) {
                Write-Verbose "Unregister ScheduledTask"
                Try { $ScheduledTask | Unregister-ScheduledTask -Confirm:$False } Catch {}
            }

            If ($ScheduledJob) {
                Write-Verbose "Unregister ScheduledJob"
                Try { $ScheduledJob | Unregister-ScheduledJob -Force -Confirm:$False | Out-Null } Catch {}
            }

        }

    }

    If ($ComputerName -or $Session) { 

        # Collection the functions to bring with us in the remote session:
        $_Function = ${Function:Invoke-ScheduledTask}.Ast.Extent.Text

        $Parameters = @{}
        If ($ComputerName)  { $Parameters['ComputerName']  = $ComputerName  }
        If ($Credential)    { $Parameters['Credential']    = $Credential    }
        If ($Session)       { $Parameters['Session']       = $Session       }
        If ($AsJob)         { $Parameters['AsJob']         = $AsJob         }
        If ($JobName)       { $Parameters['JobName']       = $JobName       }
        If ($ThrottleLimit) { $Parameters['ThrottleLimit'] = $ThrottleLimit }

        Invoke-Command @Parameters -ScriptBlock {

            # Create the functions we packed up with us previously:
            $Using:_Function | % { Invoke-Expression $_ }

            $Parameters = @{}
            If ($Using:ScriptBlock)  { $Parameters['ScriptBlock']  = [ScriptBlock]::Create($Using:ScriptBlock) }
            If ($Using:ArgumentList) { $Parameters['ArgumentList'] = $Using:ArgumentList }
            If ($Using:As)           { $Parameters['Credential']   = $Using:As           }
            If ($Using:AsSystem)     { $Parameters['AsSystem']     = $True               }
            If ($Using:AsGMSA)       { $Parameters['AsGMSA']       = $Using:AsGMSA       }
            If ($Using:RunElevated)  { $Parameters['RunElevated']  = $True               }

            Invoke-ScheduledTask @Parameters

        }

    } Else {

        $Parameters = @{}
        If ($ScriptBlock)  { $Parameters['ScriptBlock']  = $ScriptBlock  }
        If ($ArgumentList) { $Parameters['ArgumentList'] = $ArgumentList }
        If ($As)           { $Parameters['Credential']   = $As           }
        If ($AsSystem)     { $Parameters['AsSystem']     = $True         }
        If ($AsGMSA)       { $Parameters['AsGMSA']       = $AsGMSA       }
        If ($RunElevated)  { $Parameters['RunElevated']  = $True         }

        Invoke-ScheduledTask @Parameters

    }
        
}
