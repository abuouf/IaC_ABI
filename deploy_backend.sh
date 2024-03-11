echo "start deploy_backend
sudo apt update
sudo apt install -y apache2
cd /var/www/html/
sudo git clone https://github.com/abuouf/laravel.git
sudo php artisan migrate
