

Run the microservice

   python ./mydashboard -d -v --fg --nopid --conf data/conf.json

Get help

   curl http://localhost:8080/doc

Run the web interface


   curl http://localhost:8080/ui

or

   firefox http://localhost:8080/


To make a user systemd service

   cp data/mydashboard.service ~/.config/systemd/user/mydashboard.service

Set the service

   systemctl --user reload mydashboard
   systemctl --user start mydashboard
   systemctl --user enable mydashboard

