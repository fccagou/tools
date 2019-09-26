

Run the microservice

   python ./mydashboard.py -v --fg --nopid -s -D docroot

From a browser :

   firefox http://localhost:8080/


To make a user systemd service

   cat -> ~/.config/systemd/user/mydashboard.service
   [Unit]
   Description=My dashbord daemon
   
   [Service]
   ExecStart=/usr/bin/env python3  /home/fccagou/src/fccagou/tools/mydashboard/mydashboard.py -v --fg --nopid -s -D %h/src/fccagou/tools/mydashboard/docroot 
   
   [Install]
   WantedBy=default.target

Set the service

   systemctl --user reload mydashboard
   systemctl --user start mydashboard
   systemctl --user enable mydashboard

