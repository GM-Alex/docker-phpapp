# PHP development container

Including

* Apache
* MySql
* PHP 5.6, 5.5, 5.4, 5.3 and 5.2 including ioncube and zend guard loader / zend optimizer
* PhpMyAdmin
* phpbrew
* Node.js
* Sass
* Bower
* Grunt
* Gulp


## Build
```
docker build -t <yourname>/phpapp https://github.com/GM-Alex/docker-phpapp
```


## Run
```
docker run -d --name <containername> -e "PHP_VERSION=5.5" -v <yourappfolder>:/var/www:rw <yourname>/phpapp [-privileged]
```

You can choose php 5.5, 5.4, 5.3 and 5.2. Default if no env var is given is 5.5.

## MySQL

User: root
Pass: _none_ (empty password!)


## SSH user

User: root
Pass: root


## More awesomeness with docker dns

Add the following to your docker config at _/etc/default/docker_ (some times _/etc/default/docker.io_)

```
DOCKER_OPTS="-d --bip=172.17.42.1/16 --dns=172.17.42.1 --dns=8.8.8.8"
```

Clone the following repository

```
docker pull crosbymichael/skydns
docker run -d -p 172.17.42.1:53:53/udp --name skydns crosbymichael/skydns -nameserver 8.8.8.8:53 -domain docker
docker pull crosbymichael/skydock
docker run -d -v /var/run/docker.sock:/docker.sock --name skydock crosbymichael/skydock -ttl 30 -environment dev -s /docker.sock -domain docker -name skydns
```

## DNS Setup for ubuntu

There are two ways to get the dns resolving working on Ubuntu

### Using dnsmasq

Add the following line to _/etc/NetworkManager/dnsmasq.d/dnsmasq.conf_ (if the file does not exists create it)

```
server=/docker/172.17.42.1
```

and run 

```
sudo killall dnsmasq
sudo service network-manager restart
```

### Using resolve.conf

#### Disable dnsmasq

```
sudo sed -i "s/dns=dnsmasq/#dns=dnsmasq/g" /etc/NetworkManager/NetworkManager.conf
sudo killall dnsmasq
sudo service network-manager restart
cat /etc/resolv.conf
```

#### Configure resolve.conf

Add the following line to _/etc/resolvconf/resolv.conf.d/head_
```
nameserver 172.17.42.1
```

and run

```
resolvconf -u
```

### Enjoy

Now you can access your app via _http://<containername>.local.docker_.