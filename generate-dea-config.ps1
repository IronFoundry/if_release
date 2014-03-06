Param(
    [Parameter(Mandatory=$True,Position=1)]
    [string]$RouterAddress, 

    [Parameter(Mandatory=$True,Position=2)]
    [string]$CloudFoundryDomain, 

    [Parameter(Mandatory=$True,Position=3)]
    [string]$SharedSecret, 

    [string] $NatsAddress = ""
    )

	if ($NatsAddress -eq "")
	{
		$NatsAddress = $RouterAddress
	}
	
	$sourceDirectory = convert-path $PWD
	$script = "$sourceDirectory\generate-dea-config.rb" -replace "\\", "/"
	$defaultConfig = "$sourceDirectory\default-dea-config.yml" -replace "\\", "/"
	$outputConfig = "$sourceDirectory\dea.yml" -replace "\\", "/"
	& ruby "$script" "$defaultConfig" "$outputConfig" "$SharedSecret" "$RouterAddress" "$CloudFoundryDomain" "$NatsAddress"
	
	"DEA configuration written to '$outputConfig'."