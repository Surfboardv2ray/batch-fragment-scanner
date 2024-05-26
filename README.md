<h1 align="center">Batch Fragment Scanner</h1>
<h2 align="center">Batch Test v2ray fragment values to see which one works best on your network.</h2>


## How to - Windows 10

1️⃣ Ensure v2rayN is closed

To avoid conflicts, ensure any app using xray core is closed (otherwise the core process will be terminated)

2️⃣ Download Xray Core

Downlaod xray.exe from the official [Github Repository](https://github.com/XTLS/Xray-core/releases) and put it in the same folder as the powershell script.

3️⃣ Create a fragmented json config

Create config.json, can be vmess, vless or trojan. Make sure it has "fragment" attributes too, values don't matter (use tools like [IRCF Space](https://fragment.github1.cloud/) to create frag json config). Put it in the same folder as the powershell script as well.

4️⃣ Optional step: Edit the script for fragment values

✴️ Edit the Arrays of possible values for packets, length, and interval based on your need. Values are used randomly in combination.


5️⃣ Open PowerShell script:

🧧 Confirm the Execution policy bypass via typing and sending `y` to run the script.

✅ Enter number of instances, i.e the rounds of random combination of fragment values.

✅ Enter the timeout for each ping test, i.e amount of time the test will wait for response.

✅ Enter HTTP Proxy port. This depends on your json config. The deafault is 10809.

🎆 After the code runs and finishes up, you'll get the top three (best) pings with their fragment values, and logs will be saved to `pings.txt`. The file contains response time with each fragment instance, with the average response time as well.
