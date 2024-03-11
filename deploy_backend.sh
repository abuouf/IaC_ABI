echo "start deploy_backend
sudo apt update
sudo apt install -y apache2
cd /var/www/html/
git clone https://github.com/abuouf/laravel.git
php artisan migrate
