#!/bin/bash

cd /home/ubuntu/web-app
export DB_HOST=${db_host}
. ~/.bashrc
node seeds/seed.js
npm install
pm2 start app.js