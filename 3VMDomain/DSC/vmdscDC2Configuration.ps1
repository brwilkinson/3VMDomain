Configuration Main
{
Param ( 
		[String]$DomainName = 'Contoso.com',
		[PSCredential]$AdminCreds,
		[Int]$RetryCount = 15,
		[Int]$RetryIntervalSec = 60
		)

Import-DscResource -ModuleName PSDesiredStateConfiguration
Import-DscResource -ModuleName xActiveDirectory
Import-DscResource -ModuleName xStorage

Node $AllNodes.Where({$_.NodeName -eq 'DC2'}).NodeName
{
    Write-Verbose -Message $Nodename -Verbose

	LocalConfigurationManager
    {
        ActionAfterReboot   = 'ContinueConfiguration'
        ConfigurationMode   = 'ApplyOnly'
        RebootNodeIfNeeded  = $true
        AllowModuleOverWrite = $true
    }

    WindowsFeature InstallADDS
    {            
        Ensure = 'Present'
        Name   = 'AD-Domain-Services'
    }

	xDisk FDrive
    {
        DiskNumber  = 2
        DriveLetter = 'F'
    }

	File TestFile
	{
		DestinationPath = $Node.Path
		Contents        = $Node.NodeName
		DependsOn       = '[xDisk]FDrive'
	}

	WaitForAny DC1
	{
		NodeName     = '10.0.0.10'
		ResourceName = '[xWaitForADDomain]DC1Forest'
		RetryCount   = $RetryCount
		RetryIntervalSec = $RetryIntervalSec
	}

	xADDomainController DC2
	{
		DependsOn    = '[WaitForAny]DC1','[WindowsFeature]InstallADDS'
		DomainName   = $DomainName
		DatabasePath = 'F:\NTDS'
        LogPath      = 'F:\NTDS'
        SysvolPath   = 'F:\SYSVOL'
        DomainAdministratorCredential = $AdminCreds
        SafemodeAdministratorPassword = $AdminCreds
		PsDscRunAsCredential = $AdminCreds
	}
}
}#Main