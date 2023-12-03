#!/bin/bash

# Variables
repo="bootcamp-devops-2023"
USERID=$(id -u)
PKG=(
    apache2
    mariadb-server
    git
    php
    libapache2-mod-php
    php-mysql
    php-mbstring
    php-zip
    php-gd
    php-json
    php-curl
)
DISCORD="https://discord.com/api/webhooks/1169002249939329156/7MOorDwzym-yBUs3gp0k5q7HyA42M5eYjfjpZgEwmAx1vVVcLgnlSh4TmtqZqCtbupov"

# Colores
LRED='\033[1;31m'
LGREEN='\033[1;32m'
NC='\033[0m'
LBLUE='\033[0;34m'
LYELLOW='\033[1;33m'

# Validando la ejecución del script como usuario root
if [ "$USERID" -ne 0 ]; then
    echo -e "\n${LRED}Ejecutar como usuario root.${NC}"
    exit
fi

# Actualización del servidor
apt-get update -y
echo -e "\n${LGREEN} El servidor se encuentra actualizado ...${NC}"

# Validación e instalación de paquetes
for paquete in "${PKG[@]}"
do
    dpkg -s $paquete &>/dev/null
    if [ $? -eq 0 ]; then
        sleep 1
        echo -e "\n${LGREE}$paquete ya se encuentra instalado.${NC}"
    else
        apt install $paquete -y
        if [ $? -ne 0 ]; then
            echo -e "\n${LRED}Error para instalar el $paquete. ${NC}"
            exit 1
        fi
    fi
done

echo -e "\n${LGREEN} Continuando con las instalación de paquetes. ${NC}"

# Configurando la base de datos
echo -e "\n${LGREEN} Configurando la base de datos. ${NC}"
systemctl start mariadb
systemctl enable mariadb
mysql -e "
CREATE DATABASE devopstravel;
CREATE USER 'codeuser'@'localhost' IDENTIFIED BY 'codepass';
GRANT ALL PRIVILEGES ON *.* TO 'codeuser'@'localhost';
FLUSH PRIVILEGES;"

echo $?

# Instalando web
echo -e "\n${LBLUE} Instalando web. ${NC}"
sleep 1
git clone https://github.com/roxsross/$repo.git
cd $repo
git checkout clase2-linux-bash
cp -r app-295devops-travel/* /var/www/html
sed -i 's/dbPassword = ""/dbPassword = "codepass"/g' /var/www/html/config.php
cd ..


# Ejecutar script
echo -e "\n${LGREEN} Ejecuntando script para configurar la base de datos. ${NC}"
mysql < /var/www/html/database/devopstravel.sql
echo $?

# Configurando apache2
echo -e "\n${LGREEN} Configurando apache2. ${NC}"
systemctl start apache2
systemctl enable apache2
mv /var/www/html/index.html /var/www/html/index.html.bkp

# Reiniciando el servicio de apache2
systemctl reload apache2

# Verifica si se proporcionó el argumento del directorio del repositorio
if [ $# -ne 1 ]; then
  echo "Uso: $0 <ruta_al_repositorio>"
  exit 1
fi

cd "$1"

# Obtiene el nombre del repositorio
REPO_NAME=$(basename $(git rev-parse --show-toplevel))
# Obtiene la URL remota del repositorio
REPO_URL=$(git remote get-url origin)
WEB_URL="localhost"
# Realiza una solicitud HTTP GET a la URL
HTTP_STATUS=$(curl -Is "$WEB_URL" | head -n 1)


# Verifica si la respuesta es 200 OK (puedes ajustar esto según tus necesidades)
if [[ "$HTTP_STATUS" == *"200 OK"* ]]; then
  # Obtén información del repositorio
    DEPLOYMENT_INFO2="Despliegue del repositorio $REPO_NAME: "
    DEPLOYMENT_INFO="La página web $WEB_URL está en línea."
    COMMIT="Commit: $(git rev-parse --short HEAD)"
#    AUTHOR="Autor: $(git log -1 --pretty=format:'%an')"
    AUTHOR="Diego Cordero"
    DESCRIPTION="Descripción: $(git log -1 --pretty=format:'%s')"
else
  DEPLOYMENT_INFO="La página web $WEB_URL no está en línea."
fi

# Obtén información del repositorio


# Construye el mensaje
MESSAGE="$DEPLOYMENT_INFO2\n$DEPLOYMENT_INFO\n$COMMIT\n$AUTHOR\n$REPO_URL\n$DESCRIPTION"

# Envía el mensaje a Discord utilizando la API de Discord
curl -X POST -H "Content-Type: application/json" \
     -d '{
       "content": "'"${MESSAGE}"'"
     }' "$DISCORD"
