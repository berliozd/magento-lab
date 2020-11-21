#!/bin/bash

# For new env : 
# - replace hostname 'dev.magento' by new value in this file
# - update also the hostname in the vhost file in docker/nginx

echo "#############################"
echo "#  add hostname /ets/hosts  #"
echo "#############################"
HOSTNAME='dev.magento'
HOSTS_LINE='127.0.0.1 dev.magento'

if [ -n "$(grep $HOSTNAME /etc/hosts)" ]
    then
        echo "$HOSTNAME already exists : $(grep $HOSTNAME /etc/hosts)"
    else
        echo "Adding $HOSTNAME to your /etc/hosts";
        sudo -- sh -c -e "echo '$HOSTS_LINE' >> /etc/hosts";

        if [ -n "$(grep $HOSTNAME /etc/hosts)" ]
            then
                echo "$HOSTNAME was added succesfully \n $(grep $HOSTNAME /etc/hosts)";
            else
                echo "Failed to Add $HOSTNAME, Try again!";
        fi
fi

echo "#####################################"
echo "#      docker down                  #"
echo "#####################################"
docker-compose down -v

echo "#####################################"
echo "#      docker up                    #"
echo "#####################################"
sudo sysctl -w vm.max_map_count=262144
docker-compose up -d

echo "#############################"
echo "#    composer install       #"
echo "#############################"
docker-compose run -u www-data:www-data php composer install

echo "#############################"
echo "#    setting linux rights   #"
echo "#############################"

sudo chown -R www-data:www-data .
sudo  find . -type d -exec chmod 0771 {} +
sudo  find . -type f -exec chmod 0664 {} +
sudo  find . -type f -name "*.php" -exec chmod 664 {} +
sudo  find . -type f -name "*.sh" -exec chmod 0771 {} +
sudo  chmod -R 0771 bin

echo "#############################"
echo "#    remove  env.php        #"
echo "#############################"
rm -f app/etc/env.php 2> /dev/null

echo "#############################"
echo "#    magento install        #"
echo "#############################"
docker-compose run -u www-data:www-data  php php bin/magento setup:install  \
    --base-url=http://dev.magento/ --backend-frontname=admin  --language=fr_FR --timezone=Europe/Paris \
    --currency=EUR  --db-host=mysql --db-name=magento --db-user=root --db-password=password  \
    --use-secure=0 --base-url-secure=0 --use-secure-admin=0  --admin-firstname=Julien --admin-lastname=Lemaire \
    --admin-email=Juilen.lemaire@example.fr  --admin-user=admin --admin-password=admin@magento1 \
    --elasticsearch-host=elasticsearch \
    --session-save=redis --session-save-redis-host=redis --session-save-redis-db=2 \
    -vvv

echo "####################################################################################"
echo "#                               end install                                        #"
echo "#  access admin with : http://dev.magento/  [ user=admin password=admin@magento1]  #"
echo "# access db : [user=localhost login=root password=password db=magento             #"
echo "####################################################################################"
