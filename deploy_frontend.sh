echo "Start deploy frontend"
#cd /var/www
git clone https://github.com/abuouf/uptime-kuma.git
cd uptime-kuma
npm run setup
npm install pm2 -g && pm2 install pm2-logrotate
pm2 start server/server.js --name uptime-kuma
