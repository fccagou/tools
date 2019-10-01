#! /usr/bin/env python
# -*- encoding: utf-8 -*-

# This file is part of mydashboard.
# Copyright 2019 fccagou <fccagou@gmail.com>
#
# PYAP is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# mydashboard is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
# License for more details.
#
# You should have received a copy of the GNU General Public License
# along with pyap. If not, see <http://www.gnu.org/licenses/>.

from distutils.core  import setup
setup(name='mydashboard',
        version='0.0.1',
        description='Userland Dashboard microservice',
        url='http://github.com/fccagou/tools/mydashboard',
        author='fccagou',
        author_email='me@fccagou.fr',
        license='GPLv3+',
        long_description="Userland Dashboard",
        install_requires=[
            ],
        scripts=[
            'mydashboard'
            ],
        packages=[
            ],
        data_files=[
            ('share/doc/mydashboard',[
                'doc/README.md',
                'doc/LICENSE.md',
                ]),
            ('share/doc/mydashboard/samples',[
                'data/conf.json',
            ]),
            ('/etc/mydashboard/mydashboard.conf-sample', ['data/mydashboard.conf-default']),
#            ('/usr/lib/systemd/system', ['data/pyap.service']),
			('/etc/dashboard/html', ['docroot/bootstrap.min.css']),
			('/etc/dashboard/html', ['docroot/all.css']),
			('/etc/dashboard/html', ['docroot/template.html']),
			('/etc/dashboard/html', ['docroot/jquery.min.js']),
			('/etc/dashboard/html', ['docroot/bootstrap.bundle.js']),
            ],
    )
