# turn raspberry pi into router

Add the following line into crontabs to start the script each time the raspberry pi reboots

```sudo crontab -e```

At the most bottom add:

``` @reboot bash /home/pi/eth-to-wifi-route.sh & ```
