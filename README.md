<h1 align="center">Batch Fragment Scanner</h1>
<h2 align="center">Batch Test v2ray fragment values to see which one works best on your network.</h2>


### 🚩 Readme in [Farsi](https://telegra.ph/%D8%A7%D8%B3%DA%A9%D9%86%D8%B1-%D9%81%D8%B1%DA%AF%D9%85%D9%86%D8%AA-05-22)


## How to - Windows 10

1️⃣ Ensure "Curl" is installed. 
Open Command prompt and type:

`curl --version`

If there are no errors and it displays the options for curl, it’s already installed on your Windows 10. Windows 10, version 1803 and later, includes a native curl.exe in C:\Windows\System32. If not, head to https://curl.se/ and install it. Make sure to add the downloaded curl.exe to your system’s PATH.

2️⃣ Download Xray Core

Downlaod xray.exe from the official [Github Repository](https://github.com/XTLS/Xray-core/releases) and put it in your workspace folder. Let's assume the Workspace folder is located at C:\Workspace

3️⃣ Create a fragmented json config

Create config.json, can be vmess, vless or trojan. Make sure it has "fragment" attributes too, values don't matter (use tools like [IRCF Space](https://fragment.github1.cloud/) to create frag json config). Put it in the Workspace folder too.

4️⃣ Edit the PowerShell file

Edit the .ps1 file as the following:

✴️ Edit $XRAY_PATH and point to your xray.exe path. 

✴️ Edit $CONFIG_PATH and point to your config.json

✴️ Edit $LOG_FILE and point to where you want the log file to be saved.

✴️ Edit the Arrays of possible values for packets, length, and interval based on your need. Values are used randomly in combination.

✴️ Edit `$TimeoutSec` to set the timeout for ping tests.

✴️ Edit `$Instances` to set the number of instances (random rounds of fragment value combinations) you want to run.

✅ For example 

    `$Instances = 10`
  
  runs 10 instances (default is set to `10`)

5️⃣ Open Windows PowerShell as Admin

Run PowerShell as admin and use `cd` command to navigate to your workspace folder:

`cd C:\Workspace`

Then run the ps1 file:

`.\batch-fragment-test.ps1`

🧧 Exception: If you get policy error, do the following:

`Set-ExecutionPolicy Bypass -Scope Process`

and then type and send `y` to confirm. Now you can run the .ps1 file.


🎆 After the code runs and finishes up, you'll get the top three (best) pings with their fragment values, and logs will be saved at $LOG_FILE's path. The file contains response time with each fragment instance, with the average response time as well.
