# Php Development Container

## Build
```
docker build -t <yourname>/phpdev https://github.com/GM-Alex/docker-phpdev
```

## Run
```
docker run -d --name <containername> -v /home/alex/PhpstormProjects/tfm/:/var/www/:rw <yourname>/phpdev
```
