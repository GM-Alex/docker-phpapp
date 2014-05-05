# Php Development Container

## Build
```
docker build -t <yourname>/phpdev https://github.com/GM-Alex/docker-phpdev
```

## Run
```
docker run -d --name <containername> -v <yourappfolder>:/var/www:rw <yourname>/phpdev
```
