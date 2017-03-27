External Transmission (ET) v2.1.0
=================================
This script phones home;keep working external to your works' network.

Place this script on a 'Dialer' computer. It will "phone home" to your
'SwitchBoard' at home. Connect to the 'SwitchBoard' (or log in), and
ssh to localhost via the reverse connect port configured on the 'Dialer'.

Note: if you DO NOT install ssh keys this script works terribly.
(... you have to type a password EVERYTIME to connect to the 'Dialer')

Options
-------
--attempts | -a - Retry attempts
--sleep | -s - Minutes between retries
--listen-port | -l - The Dialer's SSH Listening port
--flags | -f - SSH flags for connecting to the SwitchBoard
--reverse-port | -r - The port to connect back on via the SwitchBoard
--switch-port | -w - The SwitchBoard's External SSH Port
--hostname-switch | -h - The Hostname or IP of the SwitchBoard
--username-switch | -u - The SwitchBoard's username

--install-cronjob - This will install (or update) a cronjob
--cronrule - This replaces a default callback time of 15 minutes
--cronjob - This option disables retries/sleep settings

Other Options
-------------
--license - print license
--version - print version number
--install - copy this script to /bin/(ET)
--update  - update to the most recent GitHub commit

Examples
========

15 Min Cronjob
--------------
ET --install-cronjob --debug --cronrule "*/15 * * * *"
