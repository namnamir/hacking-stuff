# Advanced PingCastle Automation Script
# This script performs a full suite of PingCastle scans, compares results, saves reports in multiple formats, and sends notifications.

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

# Define PingCastle Paths and Settings
$SendEmail = $false  # Change to $true if email is requested
$DomainName = "domain.com"  # Replace with the specific domain
$PingCastlePath = "."  # Update with the PingCastle directory
$PingCastleExecutable = Join-Path $PingCastlePath "PingCastle.exe"
$DashboardPath = "..\PingCastleDashboard"  # Update with the PingCastleDashboard directory
$DashboardExecutable = Join-Path $DashboardPath "PingCastleDashboard.exe"
$ReportFolder = Join-Path $PingCastlePath "PingCastle_Reports"
$DateSuffix = (Get-Date -Format "yyyyMMdd_HHmmss")
$OutputDir = Join-Path $ReportFolder $DateSuffix
$LogFile = Join-Path $ReportFolder "PingCastle_Log_$DateSuffix.txt"

$HTMLHeader = "﻿<div style='background: linear-gradient(45deg,#783CBD,#3845AB); display: flex; justify-content: space-between; align-items: center; margin-bottom: 2em; padding: 5px;'> <a href='$URI' target='_blank'> <img src='https://brandslogos.com/wp-content/uploads/images/large/azure-active-directory-logo.png' style='height: 3em; padding: 1em;' /> </a> <h1 style='color: #fff;'>$DomainName</h1> </div>"
$HTMLFooter = "﻿<div style='min-height: 10em; background: #0a0908; margin-top: 2em; display: flex; justify-content: center; align-items: center;'> <div style='max-width: 800px; color: #ddd; text-align: center;'> <span>Made with ❤️ by <a href="https://irsec.eu" target="_blank">IRSec</a><br>🚀 Information Security & Data Privacy</span> </div> </div>"

# Ensure report directory exists
if (-not (Test-Path $ReportFolder)) {
    New-Item -ItemType Directory -Path $ReportFolder | Out-Null
}
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

# Define the PingCastle scans to execute
$Scans = @(
    "--healthcheck --level Full --no-enum-limit --max-depth 100 --max-nodes 5000",
    "--scanner antivirus",
    "--scanner aclcheck",
    "--scanner computerversion",
    "--scanner foreignusers",
    "--scanner laps_bitlocker",
    "--scanner localadmin",
    "--scanner nullsession",
    "--scanner nullsession-trust",
    "--scanner oxidbindings",
    "--scanner remote",
    "--scanner share",
    "--scanner smb",
    "--scanner smb3querynetwork",
    "--scanner spooler"
    "--scanner startup"
    "--scanner zerologon --scmode-all"
)

# Function to Run a Single Scan
function Run-PingCastleScan {
    param (
        [string]$ScanArgument
    )
    $OutputFileHtml = Join-Path $OutputDir "{0}_{1}_{2}.html" -f $ScanArgument, $DomainName, $DateSuffix
    $OutputFileXml  = Join-Path $OutputDir "{0}_{1}_{2}.xml"  -f $ScanArgument, $DomainName, $DateSuffix

    $Arguments = " --server $DomainName $ScanArgument --log"

    try {
        Start-Process -FilePath $PingCastleExecutable -ArgumentList $Arguments -Wait
        try {
            Move-Item -Path "ad_hc_$DomainName.html" -Destination $OutputFileHtml
            Move-Item -Path "ad_hc_$DomainName.xlm"  -Destination $OutputFileXml
        } catch {
            Write-Error "Filed to move the report to the folder: $ScanArgument. Error: $_" | Tee-Object -FilePath $LogFile -Append
        }
        Write-Output "Completed scan: $ScanArgument. Reports saved in $OutputDir" | Tee-Object -FilePath $LogFile -Append
    } catch {
        Write-Error "Failed to execute scan: $ScanArgument. Error: $_" | Tee-Object -FilePath $LogFile -Append
    }
}

# Function to Compare Reports
function Compare-Reports {
    param (
        [string]$CurrentReportDir,
        [string]$PreviousReportDir
    )
    $CurrentScores = Get-Content (Join-Path $CurrentReportDir "ad_hc_$DomainName.xml")
    $PreviousScores = if (Test-Path (Join-Path $PreviousReportDir "ad_hc_$DomainName.xml")) {
        Get-Content (Join-Path $PreviousReportDir "ad_hc_$DomainName.xml")
    } else {
        $null
    }

    return $CurrentScores -ne $PreviousScores
}

# Function to Run PingCastle Dashboard
function Generate-PingCastleDashboard {
    param (
        [string]$OutputPath,
        [string]$ReportFolder
    )

    if (-not (Test-Path $DashboardExecutable)) {
        Write-Error "Dashboard executable not found: $DashboardExecutable" | Tee-Object -FilePath $LogFile -Append
        return
    }

    # Execute the dashboard generation
    try {
        Start-Process -FilePath $DashboardExecutable -ArgumentList "--XMLPath $ReportFolder --OutputPath $OutputPath" -NoNewWindow -Wait
        Write-Output "Dashboard generated successfully at $OutputPath" | Tee-Object -FilePath $LogFile -Append
    } catch {
        Write-Error "Failed to generate the dashboard: $_" | Tee-Object -FilePath $LogFile -Append
        return
    }

    # Modify header and footer
    if (Test-Path $OutputPath) {
        try {
            $DashboardContent = Get-Content $OutputPath
            $DashboardContent = $DashboardContent -replace "<header>.*?</header>", "<header>$HTMLHeader</header>"
            $DashboardContent = $DashboardContent -replace "<footer>.*?</footer>", "<footer>$HTMLFooter</footer>"
            Set-Content -Path $OutputPath -Value $DashboardContent
            Write-Output "Header and footer updated in the dashboard." | Tee-Object -FilePath $LogFile -Append
        } catch {
            Write-Error "Failed to update header and footer in the dashboard: $_" | Tee-Object -FilePath $LogFile -Append
        }
    } else {
        Write-Error "Dashboard file not found at $OutputPath." | Tee-Object -FilePath $LogFile -Append
    }
}

# Function to Send Notifications
function Send-Notification {
    param (
        [string]$ReportDir,
        [bool]$IsChanged
    )
    if (-not $SendEmail) {
        Write-Output "Email notification is disabled. Skipping email send step." | Tee-Object -FilePath $LogFile -Append
        return
    }

    $EmailRecipients = "admin@domain.com"  # Replace with recipient email
    $SMTPServer = "smtp.domain.com"        # Replace with SMTP server
    $SMTPPort = 587
    $SMTPUser = "smtp_user"                # Replace with SMTP user
    $SMTPPassword = "smtp_password"        # Replace with SMTP password
    $Subject = "PingCastle Report for $DomainName - $DateSuffix"
    $Body = if ($IsChanged) {
        "Changes detected in the PingCastle report. Please review the attached reports."
    } else {
        "No significant changes detected in the PingCastle report."
    }

    # Attach the zipped report directory
    $ZipFilePath = Join-Path $ReportFolder "PingCastle_Report_$DateSuffix.zip"
    Compress-Archive -Path $ReportDir -DestinationPath $ZipFilePath

    try {
        $MailMessage = @{
            To = $EmailRecipients
            From = "pingcastle@domain.com"
            Subject = $Subject
            Body = $Body
            SmtpServer = $SMTPServer
            Port = $SMTPPort
            Credential = New-Object System.Management.Automation.PSCredential ($SMTPUser, (ConvertTo-SecureString $SMTPPassword -AsPlainText -Force))
            UseSsl = $true
            Attachments = $ZipFilePath
        }
        Send-MailMessage @MailMessage
        Write-Output "Notification sent to $EmailRecipients" | Tee-Object -FilePath $LogFile -Append
    } catch {
        Write-Error "Failed to send email notification: $_" | Tee-Object -FilePath $LogFile -Append
    }
}

# Main Execution Logic
try {
    # Run all scans
    foreach ($Scan in $Scans) {
        Write-Host "[+] $(Get-Date -UFormat '%Y-%m-%d %R') - The Scan '$Scan' is executing."
        Run-PingCastleScan -ScanArgument $Scan
    }

    # Compare reports
    $PreviousReportDir = Get-ChildItem -Directory $ReportFolder | Sort-Object LastWriteTime -Descending | Select-Object -Skip 1 -First 1
    $ChangesDetected = $false
    if ($PreviousReportDir) {
        $ChangesDetected = Compare-Reports -CurrentReportDir $OutputDir -PreviousReportDir $PreviousReportDir.FullName
    }
    
    # Generate and modify the dashboard
    Generate-PingCastleDashboard -OutputPath $DashboardOutput -ReportFolder $OutputDir

    # Send notifications
    Send-Notification -ReportDir $OutputDir -IsChanged $ChangesDetected
} catch {
    Write-Error "Error during PingCastle execution: $_" | Tee-Object -FilePath $LogFile -Append
}

Write-Output "PingCastle automation completed. Log saved to $LogFile" | Tee-Object -FilePath $LogFile -Append
