# Email Delivery Monitoring Via Linux Server
This simple script is written in perl. It can be run manually or via cron scheduling.

## Disclaimer
The author is the original creator of this script. This script is being shared for information and/or educational purposes 
only. This script does not contain malicious intent, nor intended to cause harm or loss of business to anyone who uses it. 
All emailaddresses and user authentication used in this script are purely hypothetical and used as example only.
You are free to copy, add to, and distribute this code freely at 'your own risk'.

## Prerequisites
- At least have a working knowledge of one Linux distro.
- This script is for Linux distros, hence before you continue, please ensure that you are using a linux distro.
- Ensure that you have a working email service configured and running on your linux distro / server. If you don't, and are new to linux, some 
instructions on how to set up an email service can be found here: [How to Install and Configure a Linux Email System](http://www.linuxtopia.org/HowToGuides/linux_email_setup_guide/linux_email_intro1.html)
- Ensure that your 'target webservice function' allows for "remote / public access", and your access credentials are already set and known as they will be 
needed for the script to access the webservice.

## Script Features / Logic
In 'ideal conditions', whenever this script is run (either manually via the terminal or via cron scheduling), the following iterations occur:
- It triggers the sending of a test email via your application's 'send Email function'.
- A log message of the scripts iteration stages will be displayed in the terminal / logs if the script is run with the "debug" mode on.
- The mailbox of the 'targed recipient' is checked within a 'set time lapse', if it received any emails.
- All success / error messages are handled accordingly at each stage throughout the script's iteration.
- A 'notification email' is sent to the 'notification recipient' to report if the send email function of your webservice was successful / failed.

Note: This is a simple email delivery monitoring perl script that can be run on any linux distribution. The code is 'free' for sharing and contributing to so please be
at liberty to do so.

Enjoy!