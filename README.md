<h1 align="center">Batch Fragment Scanner</h1>
<h2 align="center">Batch Test v2ray fragment values to see which one works best on your network.</h2>

* ### Readme in [🇮🇷 Farsi](https://telegra.ph/%D8%A7%D8%B3%DA%A9%D9%86%D8%B1-%D9%81%D8%B1%DA%AF%D9%85%D9%86%D8%AA-05-27)
* ### [Android Termux/Linux](https://github.com/Ptechgithub/FragmentScanner) Version by P-Tech
* ### [YouTube Video](https://www.youtube.com/watch?v=wL3-bRxM_2o) Instructions by V2rayIrani

![0](https://raw.githubusercontent.com/Ptechgithub/configs/main/media/line.gif)

## How to - Windows 10

* Ensure v2rayN is closed

To avoid conflicts, ensure any app using xray core is closed (otherwise the core process will be terminated)

* Download Xray Core

Downlaod `xray.exe` from the official [Xray-core Github Repository](https://github.com/XTLS/Xray-core/releases) and put it in the same folder as the powershell script.

* Create a fragmented json config

Create `config.json`, can be vmess, vless or trojan. Make sure it has "fragment" attributes too, values don't matter (use tools like [IRCF Space](https://fragment.github1.cloud/) to create fragment json config). Put it in the same folder as the powershell script as well.

* Optional step: Edit the script for fragment values

✴️ Edit the .ps1 script at `Arrays of possible values` for "packets", "length", and "interval" based on your network. Values are used randomly in combination.


* Run PowerShell script:

🧧 Confirm the Execution policy bypass via typing and sending `y` to run the script.

✅ Enter number of instances, i.e the rounds of random combination of fragment values.

✅ Enter the timeout for each ping test, i.e amount of time the test will wait for response.

✅ Enter HTTP Listening port. This depends on your json config. Default is 10809.

✅ Enter number of requests per instance, i.e how many times a fragment set of values should be tested.

🎆 After the code runs and finishes up, you'll get the top three (best) pings with their fragment values, and logs will be saved to `pings.txt`. The file contains response time with each fragment instance, with the average response time as well.

🎆 Xray Core Logs are saved separately to `xraylogs.txt` so be sure to check it out after the run for detailed info and possible errors.

![0](https://raw.githubusercontent.com/Ptechgithub/configs/main/media/line.gif)
## Stargazers
[![Stargazers over time](https://starchart.cc/Surfboardv2ray/batch-fragment-scanner.svg?variant=adaptive)](https://starchart.cc/Surfboardv2ray/batch-fragment-scanner)
