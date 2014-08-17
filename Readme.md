# Php development container

Including

* Apache
* MySql
* Php 5.5, 5.4, 5.3 and 5.2
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
docker run -d --name <containername> -v <yourappfolder>:/var/www:rw <yourname>/phpapp [-privileged]
```


## SSH user

User: root
Pass: root


## More awesomeness with skydock

Add the following to your docker config at _/etc/default/docker.io_
```
DOCKER_OPTS="-d --bip=172.17.42.1/16 --dns=172.17.42.1"
```

Run the following commands
```
docker pull crosbymichael/skydns
docker run -d -p 172.17.42.1:53:53/udp --name skydns crosbymichael/skydns -nameserver 8.8.8.8:53 -domain docker
docker pull crosbymichael/skydock
docker run -d -v /var/run/docker.sock:/docker.sock --name skydock crosbymichael/skydock -ttl 30 -environment dev -s /docker.sock -domain docker -name skydns
```

Add the following to _/etc/resolvconf/resolv.conf.d/head_
```
nameserver 172.17.42.1
```

and run

```
resolvconf -u
```

Now you can access your app via _http://<containername>.phpapp.dev.docker_, nice isn't?