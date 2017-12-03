#!/bin/sh
#
# Generate a Django virtualenv
#

PYTHONVERSION="$(python --version 2>&1 | awk '{print $2}' | awk -F\. '{print $1$2}' )"

if /usr/bin/test ${PYTHONVERSION} -lt 27
then
    DJANGO_VERSION='=1.6.8'
else
    DJANGO_VERSION=''
fi



VIRTUALENV="$(which virtualenv)"

if /usr/bin/test -z "${VIRTUALENV}"
then

        printf -- "No virtualenv on this host. Getting it from github\n"
        if /usr/bin/test -d virtualenv
        then
            ( cd virtualenv && git pull)
        else
            git clone https://github.com/pypa/virtualenv.git
        fi
        VIRTUALENV="virtualenv/virtualenv.py"
fi

printf -- "Using ${VIRTUALENV}\n"


if /usr/bin/test -d django-venv
then
        printf -- "django-venv exists yet ...\n"
else

        printf -- "Creating environnement: django-venv\n"
        python ${VIRTUALENV} --no-site-package django-venv

fi

cd django-venv
. bin/activate


if /usr/bin/test -f requirements.txt
then
        printf -- "Installing/updating  requirements\n"
        pip install --requirement requirements.txt --upgrade
else
        printf -- "Installing django\n"
        pip install Django${DJANGO_VERSION}
fi

printf -- "Updating requirements.txt\n"
pip freeze > requirements.txt
cat requirements.txt


printf -- "Current installed packages\n"

pip list | sort

printf -- "Making test\n"

python -c "import django; print('You are running django version ' + django.get_version())"

printf -- "That's all folks ! \n"
