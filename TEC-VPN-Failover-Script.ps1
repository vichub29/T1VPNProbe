<

##############
### Probes ###
##############


$primaryendpoint = '10.45.115.16'
#$primaryendpoint = '10.45.115.99'

$secondaryendpoint = '10.45.115.18'
#$secondaryendpoint = '10.45.115.99'

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
}

ElseIf ($previousprimarystatus -eq $False -and $primarytest -eq $False -and $previoussecondarystatus -eq $False -and $secondarytest -eq $True ){
$result = "Secondary restored following full failure!"
# Call python script to set routes to SECONDARY
Write-Host $result
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
