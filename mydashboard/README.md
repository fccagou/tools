
# Quick run (but Unsafe way)

Run the microservice

    python ./mydashboard -d -v --fg --nopid --notoken --conf data/conf.json

Get help

    curl http://localhost:8080/doc

Run the web interface


    curl http://localhost:8080/ui

or

    firefox http://localhost:8080/


To make a user systemd servicea (still issue because of environment vars)

    mkdir -p ~/.config/systemd/user
    curl --silent http://localhost:8080/systemd/service -o ~/.config/systemd/user/mydashboard.service
    systemctl --user enable mydashboard
    systemctl --user start mydashboard



# Safe way 

In multi users environment, commands can be run by any connected user using
above commands. To avoid this security issue, remove the --notoken parameter.

Mydashboard will generate a token that must be pass as a cookie in every http
requests. This token is written in ~/.mydashboard file.

So, the token way to run mydashbard is :

    python ./mydashboard --fg --nopid --conf data/conf.json

    curl  -b "MYTOKEN=$(cat ~/.mydashboard)" http://localhost:8080/doc
    curl  -b "MYTOKEN=$(cat ~/.mydashboard)" http://localhost:8080/ui


