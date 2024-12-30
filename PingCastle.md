# Introduction
PingCastle is a security tool that checks Active Directory settings. It identifies vulnerabilities, misconfigurations, and potential risks, providing actionable insights to improve your security posture.

# Prerequisites
Before using PingCastle, ensure the following:
- Administrative access to an ICC device with local administrator privilege; there is no need for any specific domain privilege.
- Network connectivity to the domain controller(s).

# Installation
1. Download the [latest release of PingCastle from GitHub](https://github.com/netwrix/pingcastle/releases).
2. Unzip the downloaded package to a local directory on your ICC machine.

# Executing PingCastle Scan
You can use the script that will be introduced later to run PingCastle authentically. Before that, lets focus on how it works.

## Understand the Manual Execution
### Basic Health Check
1. Open a command prompt as Administrator.
2. Navigate to the PingCastle directory.
3. Run the following command to preform the health check on the AD domain
```PowerShell
# to perfom the scan in the interactive mode
PingCastle.exe --explore
# to perfom the scan on a specific domain
PingCastle.exe --healthcheck --server inter-ikea.com
```
Note: If you run it without the argument --server inter-ikea.com, it will ask for the domain name.

### Advanced Scenarios
#### Basic Arguments
```
? or help                   # Display help
--server <DOMAIN_NAME>      # Specify the target domain name
/outputdir <FOLDER>         # Save the report in a folder
```
#### Scanner Arguments
```
--healthcheck                 # Perform a health check
--risklevel                   # Look for the risk level of the domain
--scanner {SCAN_NAME}
      nullsessions                # Look for null session vulnerabilities
      smbsigning                  # Look for SMB signing requirements
      ldapsigning                 # Look for LDAP signing requirements
      ldapschannelbinding         # Look for LDAPS channel binding requirements
      checkadmincount             # Look for users with adminCount=1 attribute
      printspooler                # Check if the Print Spooler service is enabled
      zerologon                   # Look for the Zerologon vulnerability
      passwordnotrequired         # Look for accounts with the "Password Not Required" flag
      delegation                  # Look for accounts with delegation rights
      checkms14-068               # Look for vulnerability MS14-068
      checksysvol                 # Look for SYSVOL permissions
      checkdns                    # Look for DNS configurations and vulnerabilities
      listgpo                     # List all Group Policy Objects (GPOs)
```
## Automated Execution of PingCastle
[Here](https://github.com/namnamir/hacking-stuff/blob/main/scripts/PingCastle-Automation.ps1) is the automated script.

### Prerequisites
- You can either run it in the same folder as PingCastle.exe, or change the value of the variable $PingCastlePath to specify where PingCastle is. 
- It is the same for PingCastle Dashboard; make sure that the script is downloaded in the same place as PingCastle is downloaded or change the path manually $DashboardPath.
- If you need to run the scan on any other domain rather than inter-ikea.com, just mention it as the value of the variable $DomainName.
- If you need to receive the email, change the value of $SendEmail to $True. However, you have to set the SMTP values: $EmailRecipients, $SMTPServer, $SMTPPort, $SMTPUser, $SMTPPassword.
- You can change the header and footer of the dashboard by changing the values of $HTMLHeader and $HTMLFooter.
