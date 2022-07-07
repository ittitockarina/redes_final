# Docker Servidores GNU/Linux

Contenedores de docker de Ubuntu 22.04 y NGINX para poder ejecutar proxies y conexiones entre servidores

## Empezando

Estas instrucciones cubrirán la información de uso para los contenedores de docker

### Requisitos previos

Para ejecutar este contenedor, necesitará Docker instalado y Docker compose

* [Windows](https://docs.docker.com/desktop/windows/)
* [OS X](https://docs.docker.com/get-started/)
* [Linux](https://docs.docker.com/get-started/)

### Uso con Docker Compose

[Docker compose](https://docs.docker.com/compose/install/)

Crear e iniciar los contenedores

```shell
docker compose up -d
```

Para y elimna los contenedores y redes

```shell
docker compose down
```

#### Explicación de las Redes Internas

En el archivo `docker-compose.yml`

```yml
...
networks:
  lan: # Nombre de tu red
    driver: bridge
    driver_opts:
      parent: "Tu primera Interfaz de Ethernet"
    ipam:
      config:
        # Configuras la red a tu gusto
        - subnet: 192.168.1.0/24
          gateway: 192.168.1.1
...
```

En esa parte del `docker-compose.yml` hemos configurado una red similar a lo que haríamos en un servidor DHCP

Si hemos cambiado el nombre de la red `lan` a otra también se debe realizar ese cambio a las redes de los servicios `server` y `client`

```yml
...
services:
  server:
    ...
    networks:
      - lan # Nombre de tu red
    ...

  client:
    ...
    networks:
      - lan # Nombre de tu red
    ...
...
```

### Configuración para el servidor SSH

El contenido de `./ssh/sshd_config.d/default.conf`

Es esto:
```conf
PermitRootLogin yes
```

Eso es para permitir que se realice una conexión con el usuario `root`

Al iniciar los contenedores con `docker compose up -d` ejecutamos:

```shell
docker compose run -it server bash
$ service ssh start # Activamos SSH
$ passwd
...
# Establecemos una constraseña al usuario root
...
$ hostname -I
$ 192.168.1.X
```

Luego en otra terminal ejecutamos:

```shell
docker compose run -it client bash
$ ssh root@192.168.1.X
...
```
Nos pedirá la constraseña que le otorgamos al usuario root la digitamos y obtendremos la conexión

### Servidor Proxy para autenticación desde el navegador

En el archivo `docker-compose.yml`
```yml
...
  proxy:
    image: nginx:alpine
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d:ro
      - ./nginx/.htpasswd:/etc/nginx/.htpasswd:ro
      - ./html:/var/www/html:ro
    ports:
      - 8080:80
...
```

Hemos configurado los voluménes el los que podemos encontrar la configuración de NGINX y un archivo para los usuarios y sus contraseñas respectivas

En el contenido de `./nginx/conf.d/auth.conf` nos encontramos con esto:

```conf
server {
  listen 80;

  root /var/www/html;
  index index.html;

  location / {
    # Establecemos la Autenticación
    auth_basic "Restricted Access";

    ## Establecemos el archivo de los usuarios y constraseñas
    auth_basic_user_file /etc/nginx/.htpasswd;

    try_files $uri $uri/index.html =404;
  }
}
```

Las constraseñas son encriptadas y los usuarios son aquellos con los que podremos autenticarnos desde el navegador por defecto existe el usuario `test` con la constraseña `test`

`./nginx/conf.d/.htpasswd`

```htpasswd
test:$apr1$BUIMDBis$SdGrUB21dbt2Ci2BVh3Q9.

```

Si queremos agregar otro usuario con constraseña podemos ejecutar el siguiente comando:

```shell
htpasswd nginx/.htpasswd newUser
...
```

Nos pedirá ingresar los valores para la contraseña

Finalmente podemos abrir el navegador ingresar a http://localhost:8080 y veremos que nos pide autenticación

### Servidor Web

En el servicio `server` tenemos instalado nginx eso quiere decir que al saber la IP del servidor podemos comunicarnos con el asi que realizando las siguientes instrucciones podemos llegar a ello:

```shell
docker compose run -it server bash

$ service nginx start # Activamos NGINX
$ hostname -I

$ 192.168.1.X
```

En un navegador abrimos `http://192.168.1.X` y nos mostrará la página por defecto de NGINX o desde nuestra terminal o del servicio `cliente` podemos escribir:

```shell
curl http://192.168.1.X
```

Y Nos mostrará esto:

```txt
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```