param(
    [string]$username,
    [string]$password,
    [string]$domain = 'bfl',
    [int]$secretId,
    [int]$fieldOfInterest = 4,   # Beazley Standard Passwords use field 4 to store the password
    [string]$secretServerUrl = 'https://secretserver.bfl.local/webservices/sswebservice.asmx'
)

# This line allows New-WebServiceProxy to work against self-signed certificates (ala our Secret Server)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
$proxy = New-WebServiceProxy -uri $secretServerUrl -UseDefaultCredential

# Authenticate and geta token to get passwords
$result1 = $proxy.Authenticate($username, $password, '', $domain)
if ($result1.Errors.length -gt 0)
{
    $result1.Errors[0]
    exit 98
} 
$token = $result1.Token

# Using auth token now get the actual details
$result2 = $proxy.GetSecret($token, $secretId, $false, $null)
if ($result2.Errors.length -gt 0)
{
    $result2.Errors[0]
    exit 99
}

# Return the password
return $result2.Secret.Items[$fieldOfInterest].Value
