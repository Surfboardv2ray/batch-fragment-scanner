# Path to the xray executable and config file
$XRAY_PATH = "C:/Workspace/xray.exe"
$CONFIG_PATH = "C:/Workspace/config.json"
$LOG_FILE = "C:/Workspace/pings.txt"

# Arrays of possible values for packets, length, and interval
$packetsOptions = @("tlshello", "1-2", "1-5")
$lengthOptions = @("1-1", "1-5", "1-10", "3-5", "5-10", "3-10", "10-15", "10-20", "10-30")
$intervalOptions = @("1-1", "1-5", "3-5", "5-10", "10-20", "1-10", "3-10", "10-30")


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
        [string]$interval
    )

    $responseTimes = @()
    $totalTime = 0
    $timeout = $false

    for ($i = 0; $i -lt 3; $i++) {
        $startTime = Get-Date
        try {
            $result = Invoke-WebRequest -Uri "https://google.com/" -UseBasicParsing -TimeoutSec 5
            if ($result.StatusCode -eq 200) {
                $endTime = Get-Date
                $responseTime = ($endTime - $startTime).TotalSeconds
                $totalTime += $responseTime
                $responseTimes += $responseTime
            } else {
                $responseTimes += "Error: Failed to connect or fetch the URL."
            }
        } catch {
            $responseTimes += "Timeout: Request timed out."
            $timeout = $true
        }
    }

    if ($timeout) {
        return "Average: Timeout"
    } else {
        $averageTime = $totalTime / 3
        $responseTimes += "Average: $averageTime seconds"
        return $responseTimes -join "`n"
    }
}

# Main script
Start-Process -NoNewWindow -FilePath $XRAY_PATH -ArgumentList "-c $CONFIG_PATH"

Start-Sleep -Seconds 10

Clear-Content -Path $LOG_FILE

for ($i = 0; $i -lt 10; $i++) {
    $packets = Get-RandomValue -options $packetsOptions
    $length = Get-RandomValue -options $lengthOptions
    $interval = Get-RandomValue -options $intervalOptions

    Add-Content -Path $LOG_FILE -Value "Testing with packets=$packets, length=$length, interval=$interval..."
    $pingResult = Curl-Test -packets $packets -length $length -interval $interval
    Add-Content -Path $LOG_FILE -Value $pingResult
    Add-Content -Path $LOG_FILE -Value "`n"
}

Stop-Process -Name "xray" -Force
