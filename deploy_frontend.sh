echo "Start deploy frontend"
#cd /var/www
sudo apt update 
sudo apt-get install -y nodejs
sudo apt-get install -y npm
sudo npm install pm2 -g
git clone https://github.com/abuouf/uptime-kuma.git
cd uptime-kuma
sudo npm run setup
sudo npm install pm2 -g && pm2 install pm2-logrotate
sudo pm2 start server/server.js --name uptime-kuma
