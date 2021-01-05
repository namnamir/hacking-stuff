# How to install _Guacamole_ on Debian and Ubuntu
This instuction is based on the [official document of Guacamole](https://guacamole.apache.org/doc).

### Install _Guacamole_ Dependencies (with XFCE)
##### on Debian
```bash
apt update & apt upgrade
# install required dependencies
apt install libcairo2-dev libjpeg62-turbo-dev libjpeg62-dev libpng12-dev libtool-bin libossp-uuid-dev tomcat9 tomcat9-admin tomcat9-common tomcat9-user build-essential xfce4 xfce4-goodies tigervnc-standalone-server apache2
# for me the official defined ones didn't work. I used these
apt install libcairo2-dev libjpeg62-turbo-dev libjpeg-dev libpng-dev libtool-bin libossp-uuid-dev tomcat9 tomcat9-admin tomcat9-common tomcat9-user build-essential xfce4 xfce4-goodies tigervnc-standalone-server apache2

# install optional dependencies
apt install libavcodec-dev libavformat-dev libavutil-dev libswscale-dev freerdp2-dev libpango1.0-dev libssh2-1-dev libtelnet-dev libvncserver-dev libwebsockets-dev libpulse-dev libssl-dev libvorbis-dev libwebp-dev
```

##### on Ubuntu
```bash
apt update & apt upgrade
# install required dependencies
apt install libcairo2-dev libjpeg-turbo8-dev libjpeg62-dev libpng12-dev libtool-bin libossp-uuid-dev tomcat9 tomcat9-admin tomcat9-common tomcat9-user build-essential xfce4 xfce4-goodies tigervnc-standalone-server apache2

# install optional dependencies
apt install libavcodec-dev libavformat-dev libavutil-dev libswscale-dev freerdp2-dev libpango1.0-dev libssh2-1-dev libtelnet-dev libvncserver-dev libwebsockets-dev libpulse-dev libssl-dev libvorbis-dev libwebp-dev
```

### Configure and Install _Guacamole_

##### Download form Github (maybe unstable)
```bash
apt install git
git clone git://github.com/apache/guacamole-server.git
cd guacamole-server/
autoreconf -fi
```
##### Download form the website
Just get the latest _server_ version from the [website](https://guacamole.apache.org/releases/)
```bash
# in the time of writing this manual, the latest version is 1.3.0.
tar -xzf guacamole-server-1.3.0.tar.gz
cd guacamole-server-1.3.0/
```
##### Configure the installation
```bash
./configure --with-init-dir=/etc/init.d
make && make install

# update cache
ldconfig

# start guacd service after reloading systemd
systemctl daemon-reload
systemctl start guacd
systemctl enable guacd
```

### Configure the VNC Server
```bash
vncserver
```
You need to set the VNC password which will be used later in the user XML file.


### Isntall _Guacamole_ Client form the .war File

##### Download form Github (maybe unstable)
Just get the latest _Guacamole war_ file from the _client_ part of the desired version [website](https://guacamole.apache.org/releases/)
```bash
# in the time of writing this manual, the latest version of Guacamole is 1.3.0 and the tomcat's one is 9.
wget "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/1.3.0/binary/guacamole-1.3.0.war"
mv guacamole-1.3.0.war /var/lib/tomcat9/webapps/guacamole.war

# restart tomact and guacd
systemctl restart tomcat9 guacd
```

### Configure 
```
# add the guacamole home directory environment variable to tomcat
echo "GUACAMOLE_HOME=/etc/guacamole" >> /etc/default/tomcat9
```
##### Edit configuration
```bash
mkdir /etc/guacamole/
nano /etc/guacamole/guacamole.properties
```
Add the following lines to the file
```bash
# Hostname and port of guacamole proxy
guacd-hostname: localhost
guacd-port: 4822

# Auth provider class (authenticates user/pass combination, needed if using the provided login screen)
auth-provider: net.sourceforge.guacamole.net.basic.BasicFileAuthenticationProvider
basic-user-mapping: /etc/guacamole/user-mapping.xml

# Set allowed languages
allowed-languages: en
```

##### Add Users with RDP and VNC
```bash
# generate MD5 password
echo -n PLAIN_PASSWORD | openssl md5

# open user file
nano /etc/guacamole/user-mapping.xml
```

```xml
<user-mapping>

    <!-- Per-user authentication and config information -->
    <authorize
         username="USER"
         password="MD5_PASSWORD"
         encoding="md5">

       <connection name="VNC Connection">
         <protocol>vnc</protocol>
         <param name="hostname">localhost</param>
         <param name="port">5901</param>
         <param name="password">VNC_PASSWORD</param>
       </connection>

       <connection name="RDP Connection">
         <protocol>rdp</protocol>
         <param name="hostname">localhost</param>
         <param name="port">3389</param>
       </connection>
    </authorize>

</user-mapping>
```

### Configure Apache Server
use Apache as a reverse proxy
```bash
a2enmod proxy proxy_http headers proxy_wstunnel

# reset apache
systemctl restart apache2

# edit
nano /etc/apache2/sites-available/guacamole.conf
```
Add the following lines in the file.
```conf
<VirtualHost *:80>
      ServerName DOMAIN_NAME

      ErrorLog ${APACHE_LOG_DIR}/guacamole_error.log
      CustomLog ${APACHE_LOG_DIR}/guacamole_access.log combined

      <Location />
          Require all granted
          ProxyPass http://localhost:8080/guacamole/ flushpackets=on
          ProxyPassReverse http://localhost:8080/guacamole/
      </Location>

     <Location /websocket-tunnel>
         Require all granted
         ProxyPass ws://localhost:8080/guacamole/websocket-tunnel
         ProxyPassReverse ws://localhost:8080/guacamole/websocket-tunnel
     </Location>

     Header always unset X-Frame-Options
</VirtualHost>
```

Restart config file and Apache
```bash
apachectl -t

# if it shows no error continue with the following commands
a2ensite guacamole.conf
systemctl restart apache2
```

