<#

Description: This script tests whether the VPN tunnel endpoints are available, and triggers the VPN static route changes to suppport T1 VPN failover as required.

Author: Victor Miller (victor.miller@cybercx.co.nz)
Date: 20 July 2023
Version: v0.1

Version history:
v0.1 Initial draft for testing.
#>

##############
### Probes ###
##############

$primaryendpoint = '10.3.0.103'
$secondaryendpoint = '10.3.0.101'

#################
### Variables ###
#################

$primaryoutfile = 'PrimaryStatus.txt'
$secondaryoutfile = 'SecondaryStatus.txt'
#$primarytestdemo = (Test-NetConnection -ComputerName $primaryendpoint -Port 500).TCPTestSucceeded
#$secondarytestdemo = (Test-NetConnection -ComputerName $secondaryendpoint -Port 500).TCPTestSucceeded
$previousprimarystatus = Get-Content $primaryoutfile
$previoussecondarystatus = Get-Content $secondaryoutfile
$logfile = 'TC-VPN-Failover.log'
$timestamp = Get-Date -Format "dd/MM/yyyy HH:mm:ss"

####################
### Execute test ###
####################

$primarytest = (Test-NetConnection -ComputerName $primaryendpoint -ErrorAction SilentlyContinue -WarningAction SilentlyContinue).PingSucceeded 
$secondarytest = (Test-NetConnection -ComputerName $secondaryendpoint -ErrorAction SilentlyContinue -WarningAction SilentlyContinue).PingSucceeded

#############
### Logic ###
#############

If ($previousprimarystatus -eq $True -and $primarytest -eq $True){
$result = "Primary site online. Business as usual."
# No route changes required here
Write-Host $result
}

ElseIf ($previousprimarystatus -eq $True -and $primarytest -eq $False -and $secondarytest -eq $True){
$result = "Primary site has failed. Failover!"
# Call python script to set routes to SECONDARY
Write-Host $result
python.exe sddc_import_export.py -o route-secondary
}

ElseIf ($previousprimarystatus -eq $False -and $primarytest -eq $False -and $secondarytest -eq $True -and $previoussecondarystatus -eq $True){
$result = "Primary site still down. No change!"
# No route changes required here
Write-Host $result
}

ElseIf ($previousprimarystatus -eq $False -and $primarytest -eq $True){
$result = "Primary site restored. Failback!"
# Call python script to set routes to PRIMARY
Write-Host $result
python.exe sddc_import_export.py -o route-primary
}

ElseIf ($previousprimarystatus -eq $False -and $primarytest -eq $False -and $previoussecondarystatus -eq $False -and $secondarytest -eq $True ){
$result = "Secondary restored following full failure!"
# Call python script to set routes to SECONDARY
Write-Host $result
python.exe sddc_import_export.py -o route-secondary
}

Else {
$result = "Everything down!"
# No route changes required here
Write-Host $result
}


###########
### Log ###
###########

Add-Content $logfile "$timestamp,$result"


#########################################
### Write last status to output files ###
#########################################

$primarytest | Out-File $primaryoutfile
$secondarytest | Out-File $secondaryoutfile
