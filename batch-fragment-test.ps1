# Check if running on Windows 10 or Windows 11
$osVersion = [System.Environment]::OSVersion.Version

if ($osVersion.Major -eq 10) {
    # For Windows 10, set execution policy to Bypass
    Set-ExecutionPolicy Bypass -Scope Process
} elseif ($osVersion.Major -eq 11) {
    # For Windows 11, set execution policy to RemoteSigned
    Set-ExecutionPolicy RemoteSigned -Scope Process
} else {
    Write-Host "Unsupported version of Windows. Exiting script."
    exit
}

# Path to the xray executable and config file in the same folder as the script
$XRAY_PATH = Join-Path -Path $PSScriptRoot -ChildPath "xray.exe"
$CONFIG_PATH = Join-Path -Path $PSScriptRoot -ChildPath "config.json"
$LOG_FILE = Join-Path -Path $PSScriptRoot -ChildPath "pings.txt"
$XRAY_LOG_FILE = Join-Path -Path $PSScriptRoot -ChildPath "xraylogs.txt"

# Enclose paths with spaces in double quotes
$XRAY_PATH = "$XRAY_PATH"
$CONFIG_PATH = "$CONFIG_PATH"
$LOG_FILE = "$LOG_FILE"
$XRAY_LOG_FILE = "$XRAY_LOG_FILE"

# Check if xray.exe exists
if (-Not (Test-Path -Path $XRAY_PATH)) {
    Write-Host "Error: xray.exe not found"
    exit
}

# Create pings.txt and xraylogs.txt if they do not exist
if (-Not (Test-Path -Path $LOG_FILE)) {
    New-Item -Path $LOG_FILE -ItemType File
}
if (-Not (Test-Path -Path $XRAY_LOG_FILE)) {
    New-Item -Path $XRAY_LOG_FILE -ItemType File
}

# Clear the content of the log files before running the tests
Clear-Content -Path $LOG_FILE
Clear-Content -Path $XRAY_LOG_FILE

# Prompt user for input values with defaults
$InstancesInput = Read-Host -Prompt "Enter the number of instances (default is 10)"
$TimeoutSecInput = Read-Host -Prompt "Enter the timeout for each ping test in seconds (default is 10)"
$HTTP_PROXY_PORTInput = Read-Host -Prompt "Enter the HTTP Listening port (default is 10809)"
$PingCountInput = Read-Host -Prompt "Enter the number of requests per instance (default is 3)"

# Set default values if inputs are empty
$Instances = if ($InstancesInput) { [int]$InstancesInput } else { 10 }
$TimeoutSec = if ($TimeoutSecInput) { [int]$TimeoutSecInput } else { 10 }
$HTTP_PROXY_PORT = if ($HTTP_PROXY_PORTInput) { [int]$HTTP_PROXY_PORTInput } else { 10809 }
$PingCount = if ($PingCountInput) { [int]$PingCountInput + 1 } else { 4 }  # Add 1 to the user input to account for the extra request

# HTTP Proxy server address
$HTTP_PROXY_SERVER = "127.0.0.1"

# Arrays of possible values for packets, length, and interval
$packetsOptions = @("1-1", "1-2", "1-3", "1-5")
$lengthOptions = @("1-1", "1-2", "1-3", "2-5", "1-5", "1-10", "3-5", "5-10", "3-10", "10-15", "10-30", "10-20", "20-50", "50-100", "100-150")
$intervalOptions = @("1-1", "1-2", "3-5", "1-5", "5-10", "10-15", "10-20", "20-30", "20-50", "40-50", "50-100", "50-80", "100-150", "150-200", "100-200")

# Calculate the maximum possible instances
$maxPossibleInstances = $packetsOptions.Count * $lengthOptions.Count * $intervalOptions.Count

# Validate user input for instances against the maximum possible instances
while ($Instances -gt $maxPossibleInstances) {
    Write-Host "Error: Number of instances cannot be greater than the maximum possible instances ($maxPossibleInstances)"
    $InstancesInput = Read-Host -Prompt "Enter the number of instances (default is 10)"
    $Instances = if ($InstancesInput) { [int]$InstancesInput } else { 10 }
}

# Array to store top three lowest average response times
$topThree = @()

# Function to randomly select a value from an array
function Get-RandomValue {
    param (
        [array]$options
    )

    $randomIndex = Get-Random -Minimum 0 -Maximum $options.Length
    return $options[$randomIndex]
}

# Function to generate a unique combination of packets, length, and interval values
function Get-UniqueCombination {
    $combination = $null
    $usedCombinations = New-Object System.Collections.ArrayList

    do {
        $packets = Get-RandomValue -options $packetsOptions
        $length = Get-RandomValue -options $lengthOptions
        $interval = Get-RandomValue -options $intervalOptions

        $combination = "$packets,$length,$interval"
    } while ($usedCombinations -contains $combination)

    [void]$usedCombinations.Add($combination)

    return $packets, $length, $interval
}

# Function to modify config.json with random parameters
function Modify-Config {
    param (
        [string]$packets,
        [string]$length,
        [string]$interval
    )

    $config = Get-Content -Path $CONFIG_PATH | Out-String | ConvertFrom-Json

    # Find the outbound with tag 'fragment' and modify its fragment settings
    $fragmentOutbound = $config.outbounds | Where-Object { $_.tag -eq 'fragment' }
    if ($fragmentOutbound -ne $null) {
        $fragmentOutbound.settings.fragment.packets = $packets
        $fragmentOutbound.settings.fragment.length = $length
        $fragmentOutbound.settings.fragment.interval = $interval
    } else {
        Write-Host "No 'fragment' outbound found in config.json"
        return
    }

    $config | ConvertTo-Json -Depth 100 | Set-Content -Path $CONFIG_PATH
}

# Function to stop the Xray process
function Stop-XrayProcess {
    try {
        Stop-Process -Name "xray" -Force -ErrorAction Stop
    } catch {
        # Do not display "Xray process not found" message
    }
}

# Function to perform HTTP requests with proxy and measure response time
function Send-HTTPRequest {
    param (
        [int]$pingCount,
        [int]$timeout = $TimeoutSec * 1000  # Convert seconds to milliseconds
    )

    # Set the target URL
    $url = "http://cp.cloudflare.com"

    # Initialize variables to store total time and count of pings
    $totalTime = 0
    $individualTimes = @()

    # Ping the specified number of times and measure the time for each ping
    for ($i = 1; $i -le $pingCount; $i++) {
        # Create a WebRequest object
        $request = [System.Net.HttpWebRequest]::Create($url)

        # Set the timeout for the request
        $request.Timeout = $timeout

        # Set the proxy settings
        $proxy = New-Object System.Net.WebProxy($HTTP_PROXY_SERVER, $HTTP_PROXY_PORT)
        $request.Proxy = $proxy

        try {
            $elapsedTime = Measure-Command {
                # Send the HTTP request and get the response
                $response = $request.GetResponse()
            }

            # Accumulate total time
            $totalTime += $elapsedTime.TotalMilliseconds
            $individualTimes += $elapsedTime.TotalMilliseconds
        } catch {
            $individualTimes += -1  # Mark failed requests with -1
        }

        # Add a 1-second delay between each ping
        Start-Sleep -Seconds 1
    }

    # Skip the first ping result
    $individualTimes = $individualTimes[1..($individualTimes.Count - 1)]

    # Calculate average ping time, considering -1 as timeout
    $validPings = $individualTimes | Where-Object { $_ -ne -1 }
    if ($validPings.Count -gt 0) {
        $totalValidTime = $validPings | Measure-Object -Sum | Select-Object -ExpandProperty Sum
        $averagePing = ($totalValidTime + ($individualTimes.Count - $validPings.Count) * $timeout) / ($pingCount - 1)
    } else {
        $averagePing = 0
    }

    # Log individual ping times to pings.txt
    Add-Content -Path $LOG_FILE -Value "Individual Ping Times:"
    Add-Content -Path $LOG_FILE -Value ($individualTimes -join ",")

    return $averagePing
}

# Main script
# Clear the content of the log files before running the tests
Clear-Content -Path $LOG_FILE
Clear-Content -Path $XRAY_LOG_FILE

# Create a table header
$tableHeader = @"
+--------------+-----------------+---------------+-----------------+---------------+
|   Instance   |     Packets     |     Length    |     Interval    | Average Ping  |
+--------------+-----------------+---------------+-----------------+---------------+
"@

# Write the table header to the console
Write-Host $tableHeader

for ($i = 0; $i -lt $Instances; $i++) {
    $packets, $length, $interval = Get-UniqueCombination

    Modify-Config -packets $packets -length $length -interval $interval

    # Stop Xray process if running
    Stop-XrayProcess

    # Start Xray process and redirect output to xraylogs.txt
    Start-Process -NoNewWindow -FilePath "$XRAY_PATH" -ArgumentList "-c `"$CONFIG_PATH`"" -RedirectStandardOutput "$XRAY_LOG_FILE" -RedirectStandardError "$XRAY_LOG_FILE.Error"

    Start-Sleep -Seconds 3

    Add-Content -Path $LOG_FILE -Value "Testing with packets=$packets, length=$length, interval=$interval..."
    $averagePing = Send-HTTPRequest -pingCount $PingCount
    Add-Content -Path $LOG_FILE -Value "Average Ping Time: $averagePing ms`n"

    # Add the average ping time along with fragment values to the top three list
    $topThree += [PSCustomObject]@{
        Instance            = $i + 1
        Packets             = $packets
        Length              = $length
        Interval            = $interval
        AverageResponseTime = $averagePing
    }

    # Display the results in table format
    $averagePingRounded = "{0:N2}" -f $averagePing
    $tableRow = @"
|    {0,-9} | {1,-15} | {2,-13} | {3,-15} | {4,-13} |
"@ -f ($i + 1), $packets, $length, $interval, $averagePingRounded
    Write-Host $tableRow

    # Add a one-second delay between each test instance
    Start-Sleep -Seconds 1
}

# Create a table footer
$tableFooter = @"
+--------------+-----------------+---------------+-----------------+---------------+
"@
# Write the table footer to the console
Write-Host $tableFooter

# Filter out entries with an average response time of 0 ms
$validResults = $topThree | Where-Object { $_.AverageResponseTime -gt 0 }

# Sort the top three list by average response time in ascending order
$sortedTopThree = $validResults | Sort-Object -Property AverageResponseTime | Select-Object -First 3

# Display the top three lowest average response times along with their corresponding fragment values
Write-Host "Top three lowest average response times:"
$sortedTopThree | Format-Table -Property Instance, Packets, Length, Interval, @{Name='AverageResponseTime (ms)';Expression={[math]::Round($_.AverageResponseTime, 2)}}

# Stop Xray process if running
Stop-XrayProcess

# Prevent the PowerShell window from closing immediately
Read-Host -Prompt "Press Enter to exit the script..."
