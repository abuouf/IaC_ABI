echo "start deploy_backend"
cd /var/www/html
git clone https://github.com/abuouf/laravel.git
php artisan migrate
