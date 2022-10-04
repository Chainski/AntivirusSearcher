# Made by https://github.com/chainski

Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")] 
public static extern IntPtr GetConsoleWindow();
[DllImport("user32.dll")]
public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int W, int H); '

$consoleHWND = [Console.Window]::GetConsoleWindow();
$consoleHWND = [Console.Window]::MoveWindow($consoleHWND, 0, 0, 900, 900);

$console = $host.UI.RawUI
$console.WindowTitle = "Powershell Realtime AV Finder Utility"

Write-Host -ForegroundColor Red "  ╔═══╗╔╗  ╔╗     ╔═══╗╔══╗╔═╗ ╔╗╔═══╗╔═══╗╔═══╗    ╔╗ ╔╗╔════╗╔══╗╔╗   ╔══╗╔════╗╔╗  ╔╗ "
Write-Host -ForegroundColor Red "  ║╔═╗║║╚╗╔╝║     ║╔══╝╚╣╠╝║║╚╗║║╚╗╔╗║║╔══╝║╔═╗║    ║║ ║║║╔╗╔╗║╚╣╠╝║║   ╚╣╠╝║╔╗╔╗║║╚╗╔╝║ "
Write-Host -ForegroundColor Red "  ║║ ║║╚╗║║╔╝     ║╚══╗ ║║ ║╔╗╚╝║ ║║║║║╚══╗║╚═╝║    ║║ ║║╚╝║║╚╝ ║║ ║║    ║║ ╚╝║║╚╝╚╗╚╝╔╝ "
Write-Host -ForegroundColor Red "  ║╚═╝║ ║╚╝║      ║╔══╝ ║║ ║║╚╗║║ ║║║║║╔══╝║╔╗╔╝    ║║ ║║  ║║   ║║ ║║ ╔╗ ║║   ║║   ╚╗╔╝  "
Write-Host -ForegroundColor Red "  ║╔═╗║ ╚╗╔╝     ╔╝╚╗  ╔╣╠╗║║ ║║║╔╝╚╝║║╚══╗║║║╚╗    ║╚═╝║ ╔╝╚╗ ╔╣╠╗║╚═╝║╔╣╠╗ ╔╝╚╗   ║║   "
Write-Host -ForegroundColor Red "  ╚╝ ╚╝  ╚╝      ╚══╝  ╚══╝╚╝ ╚═╝╚═══╝╚═══╝╚╝╚═╝    ╚═══╝ ╚══╝ ╚══╝╚═══╝╚══╝ ╚══╝   ╚╝   "

Write-Host `r`n

Write-Host "[*] Welcome $ENV:COMPUTERNAME `r`n" -ForeGroundColor Cyan
Write-Host "[*] Starting Finder Engine `r`n" -ForeGroundColor Yellow
function ProcessingAnimation($scriptBlock) {
    $cursorTop = [Console]::CursorTop
    
    try {
        [Console]::CursorVisible = $false
        
        $counter = 0
        $frames = '|', '/', '-', '\ Loading Please Wait' 
        $jobName = Start-Job -ScriptBlock $scriptBlock
    
        while($jobName.JobStateInfo.State -eq "Running") {
            $frame = $frames[$counter % $frames.Length]
            
            Write-Host "$frame" -NoNewLine
            [Console]::SetCursorPosition(0, $cursorTop)
            
            $counter += 1
            Start-Sleep -Milliseconds 125
        }
    }
    finally {
        [Console]::SetCursorPosition(0, $cursorTop)
        [Console]::CursorVisible = $true
    }
}
ProcessingAnimation { Start-Sleep 5 } 

Write-Host "[*] Getting List of Installed AVs `r`n"  -ForeGroundColor Cyan

sleep 2

function Get-AntiVirusProduct {
    [CmdletBinding()]
    param (
    [parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [Alias('name')]
    $computername=$env:computername


    )

    #$AntivirusProducts = Get-WmiObject -Namespace "root\SecurityCenter2" -Query $wmiQuery  @psboundparameters # -ErrorVariable myError -ErrorAction 'SilentlyContinue' # did not work            
     $AntiVirusProducts = Get-WmiObject -Namespace "root\SecurityCenter2" -Class AntiVirusProduct  -ComputerName $computername

    $ret = @()
    foreach($AntiVirusProduct in $AntiVirusProducts){
        switch ($AntiVirusProduct.productState) {
        "262144" {$defstatus = "Up to date" ;$rtstatus = "Disabled"}
            "262160" {$defstatus = "Out of date" ;$rtstatus = "Disabled"}
            "266240" {$defstatus = "Up to date" ;$rtstatus = "Enabled"}
            "266256" {$defstatus = "Out of date" ;$rtstatus = "Enabled"}
            "393216" {$defstatus = "Up to date" ;$rtstatus = "Disabled"}
            "393232" {$defstatus = "Out of date" ;$rtstatus = "Disabled"}
            "393488" {$defstatus = "Out of date" ;$rtstatus = "Disabled"}
            "397312" {$defstatus = "Up to date" ;$rtstatus = "Enabled"}
            "397328" {$defstatus = "Out of date" ;$rtstatus = "Enabled"}
            "397584" {$defstatus = "Out of date" ;$rtstatus = "Enabled"}
        default {$defstatus = "Unknown" ;$rtstatus = "Unknown"}
            }

        #Create hash-table for each computer
        $ht = @{}
        $ht.Computername = $computername
        $ht.Name = $AntiVirusProduct.displayName
        $ht.'Product GUID' = $AntiVirusProduct.instanceGuid
        $ht.'Product Executable' = $AntiVirusProduct.pathToSignedProductExe
        $ht.'Reporting Exe' = $AntiVirusProduct.pathToSignedReportingExe
        $ht.'Definition Status' = $defstatus
        $ht.'Real-time Protection Status' = $rtstatus


        #Create a new object for each computer
        $ret += New-Object -TypeName PSObject -Property $ht 
    }
    Return $ret
} 
Get-AntiVirusProduct | out-file $env:userprofile\downloads\InstalledAVs.txt -force

Write-Host "[*] List of Installed AVs Saved To Your Downloads Folder `r`n" -ForeGroundColor Green

sleep 2

Write-Host "[*] Getting List of Currently Running AVs `r`n" -ForeGroundColor Yellow

sleep 2

function Get-AV {
$AVSvc = '360','ALYac','AVG Antivirus','Acronis ','Ad-Aware','AhnLab-V3','Alibaba','Antiy-AVL','Arcabit','Avast','Avira ','Baidu','BitDefender','BitDefenderTheta','Bkav Pro','CMC','ClamAV','Comodo','CrowdStrike Falcon','Cybereason','Cylance','Cynet','Cyren','Dell PBA','DrWeb','ESET-NOD32','ESM Endpoint','eScan','Elastic','Emsisoft','F-Secure','Fortinet','G DATA','GData','Google','Gridinsoft ','Ikarus','Jiangmin','K7AntiVirus','K7GW','Kaspersky Anti-virus','Kingsoft','Lionic','MAX','Malwarebytes','MaxSecure','McAfee','McAfee-GW-Edition','NANO-Antivirus','Norton','Netflow','Palo Alto Networks','Panda','QuickHeal','Rising','SUPERAntiSpyware','Sangfor Engine Zero','SecureAge','SentinelOne ','Sophos','Symantec','TACHYON','TEHTRIS','Tencent','Trapmine','Trellix ','TrendMicro','TrendMicro-HouseCall','VBA32','VIPRE','ViRobot','VirIT','Warsaw Technology','Webroot','Webroot','Windows Defender','Yandex','Zillya','ZoneAlarm by Check Point','Zoner'
$f=0
$AVSvc | % { Get-Service -DisplayName $_* | Where-Object {$_.Status -match 'Running'} | % { Write-Host $_.DisplayName`t -f White -b DarkBlue; $f++ } }
if (!$f) {return}
}

Get-AV

Write-Host `r`n

Write-Host "[*] Realtime Anti-Malware Finder Completed Successfully !`r`n" -ForeGroundColor Cyan

Read-Host -Prompt "Press any key to continue" 