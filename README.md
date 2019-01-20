# Smartthings Netgrear Wifi Presense Detection
Notify Smarttings about devices coming and going from the local Wifi network.

The solution uses a Virtual linux system or a Rasberry Pi to run a Bash script and Python script to pull device details from Netgear routers and updates Smartthing by hitting the API of a custom Application.

Many thanks to [Mathieu Velten](https://github.com/MatMaul?tab=repositories) for his [pynetgear](https://github.com/MatMaul/pynetgear) script and to [Stuart Buchanan](https://github.com/fuzzysb) for his [device](https://github.com/fuzzysb/SmartThings/blob/master/devicetypes/fuzzysb/virtual-presence-sensor.src/virtual-presence-sensor.groovy) and [smartApp](https://github.com/fuzzysb/SmartThings/blob/master/smartapps/fuzzysb/asuswrt-wifi-presence.src/asuswrt-wifi-presence.groovy) for Smartthings which are the basis for this solution.

## Setup
* Configure a virtual linux server connected to the local netwrok to host the scripts
* Install [python] and [pynetgear] using the instructions provided in the links above
* Install the scripts in this repo (see details below)
* Install the Smartthings [devices] and [smartApps] using the instructions provided in the links above
* Enjoy!!!

## Notes
* There is a very good thread about this on the [Smartthing Community](https://community.smartthings.com/t/release-asuswrt-wifi-presence/37802) site with many additional options

## Detailed Setup Instructions

1. Download and install pynetgear
```
git clone https://github.com/MatMaul/pynetgear.git (optional)
python --version
pip install pynetgear (if version is 2.x)
pip3 install pynetgear (if version is 3.x)
```
