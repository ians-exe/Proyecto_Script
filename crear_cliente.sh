#!/bin/bash

# ====================================================
#   SCRIPT DE AUTOMATIZACION DE HOSTING
#   Materia: Admin. Sistemas Operativos
#   Maquina: 24 | IP: 172.17.42.125
# ====================================================

# --- CONFIGURACION ---
IP_SERVIDOR="172.17.42.125"
DOMINIO_BASE="local"            
DB_ADMIN_NAME="hosting_admin"   
TABLA_ADMIN="registro_clientes" 

# --- PUERTOS ---
PUERTO_REAL="80"       
PUERTO_VISUAL="8024"   

# 1. VALIDACION DE ARGUMENTOS
if [ -z "$1" ]; then
    echo "Error: Debes ingresar el nombre del cliente."
    echo "Uso: sudo ./crear_cliente.sh nombre_cliente"
    exit 1
fi

USER_CLIENTE=$1
USER_CLIENTE=$(echo "$USER_CLIENTE" | tr '[:upper:]' '[:lower:]')


# Verificamos si el usuario ya existe
if id "$USER_CLIENTE" &>/dev/null; then
    echo ""
    echo "============================================="
    echo "   ALERTA: EL CLIENTE YA EXISTE"
    echo "============================================="
    echo " El usuario '$USER_CLIENTE' ya esta registrado."
    echo "============================================="
    echo ""
    exit 1 
fi

DOMINIO_FINAL="$USER_CLIENTE.$DOMINIO_BASE"
SITIO_URL="http://$DOMINIO_FINAL:$PUERTO_VISUAL"
PASSWORD=$(openssl rand -base64 8) 
DB_CLIENTE_NAME="db_$USER_CLIENTE"

# --- INSTRUCCIONES ---
INSTRUCCIONES_TEXTO="1. ACCESO A BASE DE DATOS (phpMyAdmin):
   - URL: http://adminphp.local:$PUERTO_VISUAL
   - Usuario: $USER_CLIENTE
   - Contrasena: $PASSWORD
   - Nota: Ingrese para gestionar su base de datos $DB_CLIENTE_NAME

2. CONFIGURACION WEB (Windows):
   - En Windows, abra Bloc de Notas como Administrador.
   - Edite: C:\Windows\System32\drivers\etc\hosts
   - Agregue al final: $IP_SERVIDOR   $DOMINIO_FINAL
   - Guarde y visite: $SITIO_URL

3. INSTRUCCIONES LINUX (Configurar Hosts):
   1. Abrir la terminal.
   2. Editar el archivo /etc/hosts:
      sudo nano /etc/hosts
   3. Agregar esta linea al final:
      $IP_SERVIDOR   $DOMINIO_FINAL
   4. Guardar cambios:
      CTRL + O, Enter, CTRL + X"

echo "--- Iniciando creacion de hosting para: $USER_CLIENTE ---"

# ====================================================
# PASO 1: Crear Usuario del Sistema
# ====================================================
useradd -m -s /bin/bash $USER_CLIENTE
echo "$USER_CLIENTE:$PASSWORD" | chpasswd
echo "Usuario Linux creado."

# ====================================================
# PASO 2: Directorios y Permisos
# ====================================================
DIR_HOME="/home/$USER_CLIENTE"
DIR_SITIO="$DIR_HOME/site"

mkdir -p $DIR_SITIO

chmod 755 $DIR_HOME
chown -R $USER_CLIENTE:$USER_CLIENTE $DIR_SITIO
chmod 755 $DIR_SITIO

# ====================================================
# PASO 3: Pagina de Bienvenida
# ====================================================
INSTRUCCIONES_HTML=$(echo "$INSTRUCCIONES_TEXTO" | sed ':a;N;$!ba;s/\n/<br>/g')

cat <<EOF > $DIR_SITIO/index.html
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Hosting $USER_CLIENTE</title>
    <style>
        body { font-family: sans-serif; background: #f4f4f9; padding: 40px; display: flex; justify-content: center; }
        .card { background: white; width: 100%; max-width: 700px; padding: 30px; border-radius: 8px; box-shadow: 0 4px 10px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; text-align: center; border-bottom: 2px solid #3498db; padding-bottom: 10px; }
        .grid { display: grid; grid-template-columns: 150px 1fr; gap: 10px; margin-top: 20px; }
        .label { font-weight: bold; color: #555; }
        .value { font-family: monospace; color: #333; background: #eee; padding: 2px 5px; border-radius: 4px; }
        .instructions { margin-top: 25px; background: #fff3cd; padding: 15px; border-left: 5px solid #ffc107; border-radius: 4px; }
        .instructions h3 { margin-top: 0; color: #856404; }
        .instructions p { font-size: 0.9em; line-height: 1.5; font-family: monospace; white-space: pre-wrap; }
        a { color: #007bff; text-decoration: none; }
    </style>
</head>
<body>
    <div class="card">
        <h1>Bienvenido, $USER_CLIENTE!</h1>
        <p>Tu servicio de hosting en la <strong>Maquina 24</strong> esta activo.</p>

        <div class="grid">
            <span class="label">Usuario:</span>
            <span class="value">$USER_CLIENTE</span>

            <span class="label">Contrasena:</span>
            <span class="value">$PASSWORD</span>

            <span class="label">Sitio Web:</span>
            <span class="value"><a href="$SITIO_URL">$SITIO_URL</a></span>
            
            <span class="label">Base de Datos:</span>
            <span class="value">$DB_CLIENTE_NAME</span>
        </div>

        <div class="instructions">
            <h3>Instrucciones Adicionales:</h3>
            <p>$INSTRUCCIONES_TEXTO</p>
        </div>
    </div>
</body>
</html>
EOF
chown $USER_CLIENTE:$USER_CLIENTE $DIR_SITIO/index.html

# ====================================================
# PASO 4: Configurar Nginx 
# ====================================================
CONF_NGINX="/etc/nginx/sites-available/$USER_CLIENTE"

cat <<EOF > $CONF_NGINX
server {
    listen $PUERTO_REAL;
    server_name $DOMINIO_FINAL;

    root $DIR_SITIO;
    index index.html index.php;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:$(ls /run/php/php*-fpm.sock | head -1);
    }
}
EOF

ln -sf $CONF_NGINX /etc/nginx/sites-enabled/ 2>/dev/null

if nginx -t > /dev/null 2>&1; then
    systemctl reload nginx
    echo "Nginx configurado correctamente."
else
    echo "Error en configuracion de Nginx."
fi

# ====================================================
# PASO 5: Base de Datos del Cliente
# ====================================================
sudo mariadb -u root -e "CREATE DATABASE IF NOT EXISTS $DB_CLIENTE_NAME; CREATE USER IF NOT EXISTS '$USER_CLIENTE'@'localhost' IDENTIFIED BY '$PASSWORD'; ALTER USER '$USER_CLIENTE'@'localhost' IDENTIFIED BY '$PASSWORD'; GRANT ALL PRIVILEGES ON $DB_CLIENTE_NAME.* TO '$USER_CLIENTE'@'localhost'; FLUSH PRIVILEGES;"

echo "Base de datos creada."

# ====================================================
# PASO 6: Registro en Admin
# ====================================================
SQL_ADMIN="INSERT INTO $TABLA_ADMIN (user, password, sitio, instrucciones) VALUES ('$USER_CLIENTE', '$PASSWORD', '$SITIO_URL', '$INSTRUCCIONES_TEXTO');"

sudo mariadb -u root -e "$SQL_ADMIN" $DB_ADMIN_NAME

echo ""
echo "============================================="
echo "        CLIENTE DESPLEGADO CON EXITO"
echo "============================================="
echo "  Cliente:  $USER_CLIENTE"
echo "  Password: $PASSWORD"
echo "  URL:      $SITIO_URL"
echo "============================================="
echo "Verifique el registro en: http://adminphp.local:$PUERTO_VISUAL"
echo "============================================="
