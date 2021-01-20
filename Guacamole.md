# How to install _Guacamole_ on Debian and Ubuntu
This instuction is based on the [official document of Guacamole](https://guacamole.apache.org/doc).

### Install _Guacamole_ Dependencies (with XFCE)
##### on Debian
```bash
# update and upgrade current apps
apt update & apt upgrade

# install required dependencies
apt install libcairo2-dev libjpeg62-turbo-dev libjpeg62-dev libpng12-dev libtool-bin libossp-uuid-dev tomcat9 tomcat9-admin tomcat9-common tomcat9-user build-essential lxde tightvncserver xinetd apache2 sudo wget
# for me the official defined ones didn't work. I used these
apt install libcairo2-dev libjpeg62-turbo-dev libjpeg-dev libpng-dev libtool-bin libossp-uuid-dev tomcat9 tomcat9-admin tomcat9-common tomcat9-user build-essential lxde tightvncserver xinetd apache2 sudo wget

# install optional dependencies
apt install libavcodec-dev libavformat-dev libavutil-dev libswscale-dev freerdp2-dev libpango1.0-dev libssh2-1-dev libtelnet-dev libvncserver-dev libwebsockets-dev libpulse-dev libssl-dev libvorbis-dev libwebp-dev
```

##### on Ubuntu
```bash
# update and upgrade current apps
apt update & apt upgrade

# install apitude because it resolve conflicts
apt install aptitude

# install required dependencies
apt install libcairo2-dev libjpeg-turbo8-dev libjpeg62-dev libpng12-dev libtool-bin libossp-uuid-dev tomcat9 tomcat9-admin tomcat9-common tomcat9-user build-essential lxde lubuntu-desktop tightvncserver xinetd apache2
# for me the official defined ones didn't work. I used these
aptitude install libcairo2-dev libjpeg-turbo8-dev libjpeg62-dev libpng-dev libtool-bin libossp-uuid-dev tomcat9 tomcat9-admin tomcat9-common tomcat9-user build-essential lxde lubuntu-desktop tightvncserver xinetd apache2

# install optional dependencies
aptitude install libavcodec-dev libavformat-dev libavutil-dev libswscale-dev freerdp2-dev libpango1.0-dev libssh2-1-dev libtelnet-dev libvncserver-dev libwebsockets-dev libpulse-dev libssl-dev libvorbis-dev libwebp-dev
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
wget "https://downloads.apache.org/guacamole/1.3.0/source/guacamole-server-1.3.0.tar.gz"
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
##### Configure Multi-User Login
```bash
# run xinetd on a one-time basis by using its System V (SysV) startup script
etc/init.d/xinetd start

# run xinetd automatically when the computer boots
update-rc.d xinetd enable
```
Add the following line to `/etc/xinetd.d/vnc`. Remeber to set the port as the one the file `/etc/guacamole/user-mapping.xml` (see below).
```bash
service vnc
{
   disable     = no
   socket_type = stream
   protocol    = tcp
   wait        = no
   user        = nobody
   server      = /usr/bin/Xvnc
   server_args = -inetd -once -query localhost -geometry 1024x720 -depth 16
   type        = UNLISTED
   port        = 5901
}
```
Let's assume that we are using _LightDM_ as the XDMCP server. Then we need to enable XDMCP it in the config file which is `/etc/lightdm/lightdm.conf`. The _[XDMCPServer]_ part of it should be as follow:
```conf
[XDMCPServer]
enabled=true
port=177
#listen-address=
#key=
#hostname=
```
Now we need to restart GDM and run the VNC server.
```bash
# restart LightDM
/etc/init.d/lightdm restart

# run the VNC server
vncserver
```
You need to set the VNC password which will be used later in the user XML file.


### Isntall _Guacamole_ Client form the .war File

##### Download form Github (maybe unstable)
Just get the latest _Guacamole war_ file from the _client_ part of the desired version [website](https://guacamole.apache.org/releases/)
```bash
# create the Guacamole folder and one for library and extension, if there is nothing
mkdir /etc/guacamole
mkdir /etc/guacamole/{extensions,lib}

# in the time of writing this manual, the latest version of Guacamole is 1.3.0 and the tomcat's one is 9.
wget "https://mirrors.estointernet.in/apache/guacamole/1.3.0/binary/guacamole-1.3.0.war"
mv guacamole-1.3.0.war /var/lib/tomcat9/webapps/guacamole.war

# restart tomact and guacd
systemctl restart tomcat9 guacd
```

### Configure 
```
# create a symbolic link of the guacamole client to Tomcat webapps directory
ln -s /etc/guacamole/guacamole.war /var/lib/tomcat9/webapps/

# set the guacamole home directory environment variable and add it to /etc/default/tomcat9 configuration file
echo "GUACAMOLE_HOME=/etc/guacamole" >> /etc/default/tomcat9
```
##### Edit configuration
Add the following lines to the file `/etc/guacamole/guacamole.properties`.
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

if it shows the error _AH00558: apache2: Could not reliably determine the server's fully qualified domain name, using 172.17.0.2. Set the 'ServerName' directive globally to suppress this message_ just add the following line to the end of the file `/etc/apache2/apache2.conf`.
```conf
ServerName 127.0.0.1
```

And restart the _Apache_ server.
```bash
systemctl restart apache2
```


### Other Configuarions
```bash
# create a user
adduser USERNAME

# add the user to sudo and netdev groups
usermod -aG netdev,sudoer USERNAME ### for Debian
usermod -aG netdev,sudo USERNAME ### for Ubuntu

# add 127.0.1.1 to the hosts file
nano /etc/hosts
# and add the following line
127.0.1.1 HOSTNAME
```

