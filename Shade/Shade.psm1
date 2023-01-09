class shade {
    [string]$Domain
    [string]$Ping_Status
    [string]$Html_Status
    [datetime]$Date_Checked
    [string]$Subject
    [string]$Emails
    [string]$Type
    [string]$Send

    [void] show($temp){
        write-host $this.Emails $temp
    }
}

$path = "~\shade"

function Send-ShadeAlert {
    param (
        [pscredential]$login = $(Import-Clixml "$path\cred.xml"),
        [pscustomobject]$smtp_server = $(Get-Content -raw "$path\server.json" | ConvertFrom-Json),
        [hashtable]$email_info = $null
    )




    Try{

        
        Send-MailMessage -SmtpServer $smtp_server.smtp_server -Verbose -UseSsl -Port $smtp_server.smtp_port -Credential $login @email_settings
           
        
    
    }



    Catch{
        Write-Host "ERROR email" -ForegroundColor Red
    }
    
}





function Test-Shade {

    <#
        .SYNOPSIS
        Test user specified domains

        .Description
        The Test-Shade function tests all domains in your domains.json config file

        .EXAMPLE
        Test-Shade

        
    #>

    #Define function parameters
    param (
        [array]$current = $null

    )


    $domains = Get-Content -Raw "$path\domains.json" | ConvertFrom-Json

    #Try block for ping and HTML status then conversion to HTML
    

    Try{
        if($(Test-Path $path) -ne $true){
                New-Item -ItemType Directory -Path $path
         }
    }

    Catch [System.UnauthorizedAccessException]{
         Write-Message "Error you don't have write permissions for $path"
    }



    #Ping and HTML status each user domain 
    foreach($i in $domains.Domains ){

        if($i.Type -eq "ping" -or $i.Type -eq "both"){
            if($(Test-Connection $i.Domain -Quiet -Count 1) -eq $true){
                $ping_status = "OK"
            }

            else{
                $ping_status = "FAIL"
            }
        }

        else{
            $ping_status = $false
        }

        if($i.Type -eq "http" -or $i.Type -eq "both"){
            Try{
                
                $html_status = Invoke-WebRequest $i.Domain
            
                }
                
            Catch{
                [pscustomobject]$html_status = @{StatusCode = "FAIL"}
            }
        }

        else{
            $html_status = $false
        }

        #Create object for each domains results then store in arrary object $current
        $current += ([shade]@{Domain = $i.Domain;Ping_Status = $ping_status;Html_Status = $html_status.StatusCode;Date_Checked = $(Get-Date);Subject = $i.Subject; Emails = $i.Emails; Type = $i.Type; Send = $i.send})
        }
     
        
    Try{    
        #Convert objects stored in $current to HTML
        $current | ConvertTo-Html | Out-File "$path\domains.html"


    }

    Catch [System.UnauthorizedAccessException]{
        Write-Message "Error you don't have the correct file system permissions for $path\domains.html" -BackgroundColor Red
    }


    foreach($i in $current){
        
        if($i.Type -eq "both"){
            if($i.Ping_Status -ne "OK" -or $i.Html_Status -ne "OK"){
                $email_settings = @{To = ($i.emails).Split(",").Trim();From = $i.send;Subject = $i.subject;Body = "$($i.Domain) is currently down! Ping status is $($i.Ping_Status) HTML status is $($i.Html_Status)"}
                Send-ShadeAlert -email_info $email_settings
            }
        }

        elseif($i.Type -eq "ping"){
            if($i.Ping_Status -ne "OK"){
                $email_settings = @{To = ($i.emails).Split(",").Trim();From = $i.send;Subject = $i.subject;Body = "$($i.Domain) is currently down! Ping status is $($i.Ping_Status)"}
                Send-ShadeAlert -email_info $email_settings
            }
        }

        elseif($i.Type -eq "http"){
            if($i.Ping_Status -ne "OK"){
                $email_settings = @{To = ($i.emails).Split(",").Trim();From = $i.send;Subject = $i.subject;Body = "$($i.Domain) is currently down! HTML status is $($i.HTML_Status)"}
                Send-ShadeAlert -email_info $email_settings
            }
        }


    }
    
    
   
 }






function Set-ShadeEmail {
    <#
        .SYNOPSIS
        Set user email account info

        .Description
        The Set-ShadeEmail function requests user email account and server info then updates user config file

        .EXAMPLE
        Set-ShadeEmail

        
    #>

    param (
        [string]$username = $(Read-Host -Prompt "Enter your email username"),
        [securestring]$password = $(Read-Host -AsSecureString -Prompt "Enter your email password"),
        [string]$smtp_server = $(Read-Host -Prompt "Enter your SMTP server address without port"),
        [string]$smtp_port = $(Read-Host -Prompt "Enter your SMTP server port")
    )

    [pscredential]$login = $(New-Object System.Management.Automation.PSCredential ($username,$password))
    [pscustomobject]$server = @{smtp_server = $smtp_server; smtp_port = $smtp_port}
    
    try {
        if($(Test-Path $path) -eq $false){
            New-Item -ItemType Directory $path *> $null
        }

        $login | Export-Clixml -Path "$path\cred.xml" -Force
        $server | Convertto-Json | Out-File "$path\server.json" -Force
        Write-Host "Your email settings have been saved!" -ForegroundColor Blue

    }


    catch [System.UnauthorizedAccessException] {
        Write-Host "You don't have file system permissions for $path." -ForegroundColor Red
    }
    
    
}


function Add-ShadeDomain {
    <#
        .SYNOPSIS
        Adds a new domain to user domains.json config file

        .Description
        The Add-ShadeDomain function asks for user input then adds a new domain to domains.json

        .EXAMPLE
        Add-ShadeDomain

        
    #>

    param (
        [string]$domain = $(Read-Host -Prompt "Enter one domain like test.com"),
        [string]$send = $(Read-Host -Prompt "Enter the address you want the alert sent from"),
        [string]$subject = $(Read-Host -Prompt "Enter the subject for alert emails"),
        [string]$emails = $(Read-Host -Prompt "Enter the emails you want the alert sent to eq test@test.com, test2@test.com"),
        [string]$type = $(Read-Host -Prompt "Do you want to test this domain via ping, HTTP status, or both? Type ping, http, or both.")
        
    )

    try {
        if($(Test-Path $path) -eq $false){
            New-Item -ItemType Directory $path *> $null
        }
    }

    catch [System.UnauthorizedAccessException] {
        Write-Host "You don't have file system permissions for $path." -ForegroundColor Red
    }    


    if ($type -like "ping") {
        $type = "ping"
        
    }
    
    elseif ($type -like "http") {
        $type = "http"
    }
    
    elseif ($type -like "both") {
        $type = "both"
    }
    
    else{
        throw "Invalid choice for test type! Try again with ping, http, or both!"
    }



    try{
        if ($(Test-Path "$path\domains.json") -eq $true){
            $Current_Config = Get-Content -Raw "$path\domains.json" | ConvertFrom-Json
        }
        
        else{
            [psobject]$Current_Config = @{domains = @()}
            }
    
    }

    Catch [System.UnauthorizedAccessException]{
        Write-Message "Error you don't have the correct file system permissions for $path\domains.json" -BackgroundColor Red
   }

        

    
    $Current_Config.domains += [PSCustomObject]@{Domain = $domain;send = $send ;Subject = $subject; Emails = $emails; Type = $type}

    
    try{
        $Current_Config | ConvertTo-Json | Out-File -Force "$path\domains.json"

        Write-Host "Your domain setting have been saved!" -ForegroundColor Blue
    }

    Catch [System.UnauthorizedAccessException]{
        Write-Message "Error you don't have the correct file system permissions for $path\domains.json" -BackgroundColor Red
   }
}


function Remove-ShadeDomain {
    <#
        .SYNOPSIS
        Removes domain from user's domains.json config file

        .Description
        The Remove-ShadeDomain function asks user for input then removes a domain from domains.json

        .EXAMPLE
        Remove-ShadeDomain

        
    #>

    param (
        $New_Config = $([pscustomobject]@{domains = @()}),
        $Current_Config = $(Get-Content -Raw "$path\domains.json" | ConvertFrom-Json)
        
    )

    $Current_Config.domains | Out-Host

    [string]$domain = $(Read-Host -Prompt "Enter one domain you want to remove eq test.com")

    foreach($i in $Current_Config.domains){
        if($i.domain -ne $domain){
            $New_Config.domains += $i
        }

    }

    try{
        $New_Config | ConvertTo-Json | Out-File -Force "$path\domains.json"

        Write-Host "Your domain setting have been saved!" -ForegroundColor Blue
    }

    Catch [System.UnauthorizedAccessException]{
        Write-Message "Error you don't have the correct file system permissions to $path\domains.json" -BackgroundColor Red
   }

    
}


Function Set-ShadeTimer{

    <#
        .SYNOPSIS
        Creates Windows task for test-shade

        .Description
        The Set-Shadetimer function opens an admin shell and ask the user for input then creates a Windows task.

        .EXAMPLE
        Set-Shadetimer

        
    #>


    $script = {
        [int]$time = $(Read-Host -Prompt "'How many minutes do you want between domain tests '")

        $trigger = New-ScheduledTaskTrigger -Once:$true -At $(Get-Date) -RepetitionInterval $(New-TimeSpan -Minutes $time)

        $action = New-ScheduledTaskAction -Execute 'Powershell.exe'`
            -Argument '-WindowStyle Hidden -command "&{Test-Shade}"'

        $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType S4U
    
        try{
            Register-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -TaskName "Shade" 2>> $path\shadeerror.log

        }

        catch{
            Write-Host "Error making Windows task! Check ${path}\shaderror.log" -BackgroundColor Red
        }

        Read-Host -Prompt "'Press enter to close this window!'"

        exit
    }

    try{
        
        Start-Process powershell -ArgumentList "-noexit -command (Invoke-Command -ScriptBlock {$script})" -verb RunAs
        Write-Host "Your Shade timer has been set!" -BackgroundColor Blue

    }

    catch{
        Write-Host "Error making Windows task! Check ${path}\shaderror.log" -BackgroundColor Red
    }
}


function Remove-ShadeTimer {
    
    <#
        .SYNOPSIS
        Removes Windows task for test-shade

        .Description
        The Remove-Shadetimer function opens an admin shell and removes the current Shade Windows task.

        .EXAMPLE
        Remove-Shadetimer

        
    #>


    $script = {

        Unregister-ScheduledTask -TaskName Shade -force 2>> $path\shadeerror.log


    
    }


    try{
        
        Start-Process powershell -ArgumentList "-noexit -command (Invoke-Command -ScriptBlock {$script})" -verb RunAs
        Write-Host "Your Shade timer has been removed!" -BackgroundColor Blue

    }

    catch{
        Write-Host "Error removing Windows task! Check ${path}\shaderror.log" -BackgroundColor Red
    }

}


