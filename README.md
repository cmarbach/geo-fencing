# geo-fencing
Linux shell script to implement IP geo-fencing

Copy geo-fencing to /etc/init.d and make it executable by root
  * chown root.root /etc/init.d/geo-fencing
  * chmod 755 /etc/init.d/geo-fencing)
  * update-rc.d geo-fencing defaults
  * update-rc.d geo-fencing enable
Copy allow-by-country.sh to /opt/geo-fencing
  * mkdir /opt/geo-fencing
  * cp allow-by-country.sh /opt/geo-fencing
  * chown root.root /opt/geo-fencing/allow-by-country.sh
  * chmod 755 /opt/geo-fencing/allow-by-country.sh
Adapt filtering rules (allows networks + allowed countries)
Execute the the script a first time to create data directory (list of IPs by country) and filtering rules file.

The filtering file is loaded at startup without requiring download + creation of IP filtering rules.

Refreshing the IPs by country is performed using a crontab entry that executes allow-by-country.sh script on a regular basis.
For example every 1st day of month during the night.
