<h1 align="center">Batch Fragment Scanner</h1>
<h2 align="center">Batch Test v2ray fragment values to see which one works best on your network.</h2>

### Readme in [🇮🇷 Farsi](https://telegra.ph/%D8%A7%D8%B3%DA%A9%D9%86%D8%B1-%D9%81%D8%B1%DA%AF%D9%85%D9%86%D8%AA-05-27)

## How to - Windows 10

* Ensure v2rayN is closed

To avoid conflicts, ensure any app using xray core is closed (otherwise the core process will be terminated)

* Download Xray Core

Downlaod `xray.exe` from the official [Github Repository](https://github.com/XTLS/Xray-core/releases) and put it in the same folder as the powershell script.

* Create a fragmented json config

Create `config.json`, can be vmess, vless or trojan. Make sure it has "fragment" attributes too, values don't matter (use tools like [IRCF Space](https://fragment.github1.cloud/) to create fragment json config). Put it in the same folder as the powershell script as well.

* Optional step: Edit the script for fragment values

✴️ Edit the .ps1 script at `Arrays of possible values` for "packets", "length", and "interval" based on your network. Values are used randomly in combination.


* Run PowerShell script:

🧧 Confirm the Execution policy bypass via typing and sending `y` to run the script.

✅ Enter number of instances, i.e the rounds of random combination of fragment values.

✅ Enter the timeout for each ping test, i.e amount of time the test will wait for response.

✅ Enter HTTP Proxy port. This depends on your json config. The deafault is 10809.

🎆 After the code runs and finishes up, you'll get the top three (best) pings with their fragment values, and logs will be saved to `pings.txt`. The file contains response time with each fragment instance, with the average response time as well.
