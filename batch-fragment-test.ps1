# Path to the xray executable and config file
$XRAY_PATH = "C:/Workspace/xray.exe"
$CONFIG_PATH = "C:/Workspace/config.json"
$LOG_FILE = "C:/Workspace/pings.txt"

# Timeout for each ping test in seconds
$TimeoutSec = 5

# Arrays of possible values for packets, length, and interval
$packetsOptions = @("tlshello", "1-2", "1-5")
$lengthOptions = @("1-1", "1-5", "1-10", "3-5", "5-10", "3-10", "10-15", "10-30", "10-20", "20-50", "50-100", "100-150")
$intervalOptions = @("1-1", "1-5", "5-10", "10-20", "20-50", "40-50", "50-100", "100-150", "150-200", "100-200")

# Number of instances to run
$Instances = 10

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

# Function to perform a curl test and log the response time
function Curl-Test {
    param (
        [string]$packets,
        [string]$length,
        [string]$interval,
        [int]$timeout
    )

    $responseTimes = @()
    $totalTime = 0
    $timeoutOccurred = $false

    for ($i = 0; $i -lt 3; $i++) {
        $startTime = Get-Date
        try {
            # Build the curl command with SOCKS5 proxy (HTTPS request)
            $curlCommand = "curl --verbose --proxy SOCKS5://127.0.0.1:10808 --max-time $timeout https://google.com/"

            # Execute the curl command through CMD and capture the output
            $output = cmd.exe /c "$curlCommand"

            # Debug output
            Add-Content -Path $LOG_FILE -Value "Ping $($i + 1):"
            Add-Content -Path $LOG_FILE -Value $output

            # Check for a successful response
            if ($output -match "HTTP/\d+\.\d+\s+200\s+OK") {
                $endTime = Get-Date
                $responseTime = ($endTime - $startTime).TotalSeconds
                $totalTime += $responseTime
                $responseTimes += $responseTime
            } else {
                $responseTimes += "Error: Request failed."
            }
        } catch {
            $responseTimes += "Timeout: Request timed out."
            $timeoutOccurred = $true
        }
    }

    if ($timeoutOccurred) {
        $responseTimes += "Average: Timeout"
    } else {
        $averageTime = $totalTime / 3
        $responseTimes += "Average: $averageTime seconds"
    }

    return $responseTimes -join "`n"
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

# Main script
# Clear the content of the log file before running the tests
Clear-Content -Path $LOG_FILE

for ($i = 0; $i -lt $Instances; $i++) {
    $packets = Get-RandomValue -options $packetsOptions
    $length = Get-RandomValue -options $lengthOptions
    $interval = Get-RandomValue -options $intervalOptions

    Modify-Config -packets $packets -length $length -interval $interval

    # Stop Xray process if running
    try {
        Stop-Process -Name "xray" -Force -ErrorAction Stop
    } catch {
        Write-Host "Xray process not found, starting new instance."
    }

    Start-Process -NoNewWindow -FilePath $XRAY_PATH -ArgumentList "-c $CONFIG_PATH"

    Start-Sleep -Seconds 10

    Add-Content -Path $LOG_FILE -Value "Testing with packets=$packets, length=$length, interval=$interval..."
    $pingResult = Curl-Test -packets $packets -length $length -interval $interval -timeout $TimeoutSec
    Add-Content -Path $LOG_FILE -Value $pingResult
    Add-Content -Path $LOG_FILE -Value "`n"

    # Extract average response time from the result
    $averageResponseTime = ($pingResult -split "`n" | Where-Object { $_ -match "Average:" }) -replace "Average: " -replace " seconds", "" -as [double]

    # Add the average response time along with fragment values to the top three list
    $topThree += [PSCustomObject]@{
        AverageResponseTime = $averageResponseTime
        Packets = $packets
        Length = $length
        Interval = $interval
    }

    # Add a one-second delay between each test instance
    Start-Sleep -Seconds 1
}

# Sort the top three list by average response time in ascending order
$sortedTopThree = $topThree | Sort-Object -Property AverageResponseTime

# Display the top three lowest average response times along with their corresponding fragment values
Write-Host "Top three lowest average response times:"
for ($i = 0; $i -lt 3; $i++) {
    $item = $sortedTopThree[$i]
    Write-Host "Average Response Time: $($item.AverageResponseTime) seconds"
    Write-Host "Packets: $($item.Packets), Length: $($item.Length), Interval: $($item.Interval)"
    Write-Host ""
}

# Display a message indicating that the tests have finished
Write-Host "Ping tests completed. Results are logged in: $LOG_FILE"

# Stop Xray process after all tests
try {
    Stop-Process -Name "xray" -Force
} catch {
    Write-Host "Xray process not found."
}
