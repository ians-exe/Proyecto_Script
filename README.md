# Proyecto_Script
Proyecto Final - Script crear_cliente
# ⚙️ Script de Automatización de Hosting (`crear_cliente.sh`)

Este script de shell (`bash`) automatiza el despliegue completo de un nuevo cliente de hosting en un servidor Linux (probablemente Ubuntu/Debian, dada la dependencia de `systemctl` y `nginx`). Gestiona la creación de usuarios del sistema, la configuración web (Nginx) y la configuración de bases de datos (MariaDB/MySQL).

## 🚀 Requisitos del Sistema (Servidor)

Este script asume que el servidor Linux (la "Máquina 24" con IP `172.17.42.125`) tiene instalados y configurados los siguientes servicios:

* **Servidor Web:** Nginx.
* **Servidor de Base de Datos:** MariaDB o MySQL.
* **Intérprete de PHP:** PHP-FPM (necesario para la configuración PHP incluida en Nginx).
* **Herramientas de Usuario y Sistema:** `useradd`, `chpasswd`, `openssl`, `mariadb`.

## 🛠️ Instalación y Configuración

El script está diseñado para ser ejecutado directamente en la máquina servidora con permisos de `root` (usando `sudo`).

### 1. Configuración de Variables

Asegúrate de que las variables de configuración en la parte superior del script (`IP_SERVIDOR`, `DOMINIO_BASE`, etc.) coincidan con tu entorno antes de la ejecución.

### 2. Permisos de Ejecución

Antes de usar, debes darle permisos de ejecución al archivo:

```bash
chmod +x crear_cliente.sh
