# ihoochie_microservices [![Build Status](https://travis-ci.com/otus-devops-2019-05/ihoochie_microservices.svg?branch=master)](https://travis-ci.com/otus-devops-2019-05/ihoochie_microservices)

[ДЗ №12: Технология контейнеризации. Введение в Docker](#дз-12-технология-контейнеризации-введение-в-docker)
* [Docker-образы и контейнеры](#docker-образы-и-контейнеры)
* [Задание со * 1](#задание-со-звездочкой-1-отличие-образа-от-контейнера)
* [Docker hub](#docker-hub)
* [Задание со * 2](#задание-со-звездочкой-2-создание-инстансов-с-утавноленным-докером-и-запущенным-контейнером-с-приложением)

[ДЗ №13: Docker-образы. Микросервисы](#дз-13-docker-образы-микросервисы)
* [Приложение в микросервисной архитектуре](#приложение-в-микросервисной-архитектуре)
* [Задание со * 1](#задание-со-звездочкой-1-запуск-контейнеров-с-другими-сетевыми-алиасами)
* [Оптимизация образов](#оптимизация-образов)

[ДЗ №14: Docker: сети, docker-compose](#дз-14-docker-сети-docker-compose)
* [Работа с сетью в Docker](#работа-с-сетью-в-docker)
* [Docker-compose](#docker-compose)

[ДЗ №15: Устройство Gitlab CI. Построение процесса непрерывной поставки](#дз-15-устройство-gitlab-ci-построение-процесса-непрерывной-поставки)
* [Инсталляция Gitlab CI](#инсталляция-gitlab-ci)
* [Разделение на окружения](#разделение-на-окружения)


#### ДЗ №12: Технология контейнеризации. Введение в Docker

##### Docker-образы и контейнеры

* Запущены контейнеры из образа ubuntu:16.04

* В контейнер внесены изменения, которые сохранены в новый образ
  ```
  $ docker commit 321231cd5ffd ihoochie/ubuntu-tmp-file
  ```
* Вывод добавлен в файл docker-monolith/docker-1.log


##### Задание со звездочкой 1: отличие образа от контейнера

* Docker-образ состоит из read-only слоев, где каждый слой - это набор отличий от предыдущего слоя.
Отличие контейнера в том, что он запускается из образа (read-only слои) с новым слоем, доступным для записи. Здесь же инициализируются различные параметры: сетевые порты, идентификаторы и лимиты ресурсов.

* Docker-контейнеры

* Создан новый проект docker в GCE

* Устанавливам Docker в GCP при помощи docker-machine
  ```
  $ export GOOGLE_PROJECT=docker-250515
  $ docker-machine create --driver google \
   --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
   --google-machine-type n1-standard-1 \
   --google-zone europe-west1-b \
   docker-host
  ```
* Переключение на удаленный хост
  ```
  $ eval $(docker-machine env docker-host)
  ```
* Проверить с каким докер-демоном работаем
  ```
   $ env | grep DOCKER
  ```
* В docker-monolith/Dockerfile описыаем создание образа

* Создание образа
  ```
  $ docker build -t reddit:latest .
  ```

* Открытие доступупа к порту 9292
  ```
  $ gcloud compute firewall-rules create reddit-app \
   --allow tcp:9292 \
   --target-tags=docker-machine \
   --description="Allow PUMA connections" \
   --direction=INGRESS
  ```

##### Docker hub

* Загрузка образа в репозитрий Docker Hub (с хоста в GCP)
  ```
  $ docker tag reddit:latest ilyahoochie/otus-reddit:1.0
  $ docker push ilyahoochie/otus-reddit:1.0
  ```
* Запуск контейнера из образа в Docker Hub (на локальном хосте)
  ```
  $ docker run --name reddit -d -p 9292:9292 ilyahoochie/otus-reddit:1.0
  ```
##### Задание со звездочкой 2: Создание инстансов с утавноленным докером и запущенным контейнером с приложением

* В директорию /docker-monolith/infra/ добавлена конфигурация, автоматизирующая создание инстансов, установку Docker и запуск контейнера

* В /docker-monolith/infra/terraform - создание нескольких инстансов в GCE
  ```
  $ terraform apply
  ```
* В /docker-monolith/infra/ansible - провижининг созданных инстансов: установка Docker и запуск контейнера из образа в Docker Hub
  ```
  $ ansible-playbook install_docker.yml
  $ ansible-playbook run_container.yml
  ```

* В /docker-monolith/infra/packer - создание образа в GCP c установленным Docker
  ```
  $ packer build -var-file=variables.json app.json
  ```

#### ДЗ №13: Docker-образы. Микросервисы

##### Приложение в микросервисной архитектуре

Создаем инструкции для создания образов:

* ./post-py/Dockerfile 
  ```
  FROM python:3.6.0-alpine

  RUN apk add --update gcc python python-dev py-pip build-base

  WORKDIR /app
  ADD . /app

  RUN pip install -r /app/requirements.txt

  ENV POST_DATABASE_HOST post_db
  ENV POST_DATABASE posts

  ENTRYPOINT ["python3", "post_app.py"]
  ```

* ./comment/Dockerfile
  ```
  FROM ruby:2.2
  RUN apt-get update -qq && apt-get install -y build-essential

  ENV APP_HOME /app
  RUN mkdir $APP_HOME
  WORKDIR $APP_HOME

  ADD Gemfile* $APP_HOME/
  RUN bundle install
  ADD . $APP_HOME

  ENV COMMENT_DATABASE_HOST comment_db
  ENV COMMENT_DATABASE comments

  CMD ["puma"]
  ```

* ./ui/Dockerfile
  ```
    FROM ruby:2.2
    RUN apt-get update -qq && apt-get install -y build-essential

    ENV APP_HOME /app
    RUN mkdir $APP_HOME

    WORKDIR $APP_HOME
    ADD Gemfile* $APP_HOME/
    RUN bundle install
    ADD . $APP_HOME

    ENV POST_SERVICE_HOST post
    ENV POST_SERVICE_PORT 5000
    ENV COMMENT_SERVICE_HOST comment
    ENV COMMENT_SERVICE_PORT 9292

    CMD ["puma"]
  ```

* Создания образов, на основании Dockerfiles для микросервисов в директории src
  ```
  $ eval $(docker-machine env docker-host)
  $ docker build -t ilyahoochie/post:1.0 ./post-py
  $ docker build -t ilyahoochie/comment:1.0 ./comment
  $ docker build -t ilyahoochie/ui:1.0 ./ui
  ```

* Создание сети:
  ```
  $ docker network create reddit
  ```

* Запуск контейнеров из созданных образов
  ```
  $ docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db mongo:latest
  $ docker run -d --network=reddit --network-alias=post ilyahoochie/post:1.0
  $ docker run -d --network=reddit --network-alias=comment ilyahoochie/comment:1.0
  $ docker run -d --network=reddit -p 9292:9292 ilyahoochie/ui:1.0
  ```

##### Задание со звездочкой 1: Запуск контейнеров с другими сетевыми алиасами

* Останавливаем контейнеры
  ```
  $ docker kill $(docker ps -q)
  ```

* Запускаем с новыми алиасами
  ```
  $ docker run -d --network=reddit --network-alias=post_db_new --network-alias=comment_db_new mongo:latest
  $ docker run -d --network=reddit --network-alias=post_new --env POST_DATABASE_HOST=post_db_new ilyahoochie/post:1.0
  $ docker run -d --network=reddit --network-alias=comment_new --env COMMENT_DATABASE_HOST=comment_db_new ilyahoochie/comment:1.0
  $ docker run -d --network=reddit -p 9292:9292 --env POST_SERVICE_HOST=post_new --env COMMENT_SERVICE_HOST=comment_new ilyahoochie/ui:1.0
  ```
* Проверяем приложение - создание остов и комментариев работает.

##### Оптимизация образов

* Меняем содержимое  ./ui/Dockerfile
  ```
  FROM ubuntu:16.04
  RUN apt-get update \
      && apt-get install -y ruby-full ruby-dev build-essential \
      && gem install bundler --no-ri --no-rdoc

  ENV APP_HOME /app
  RUN mkdir $APP_HOME

  WORKDIR $APP_HOME
  ADD Gemfile* $APP_HOME/
  RUN bundle install
  ADD . $APP_HOME

  ENV POST_SERVICE_HOST post
  ENV POST_SERVICE_PORT 5000
  ENV COMMENT_SERVICE_HOST comment
  ENV COMMENT_SERVICE_PORT 9292

  CMD ["puma"]
  ```

* Запускаем новые копии контейнеров
  ```
  $ docker kill $(docker ps -q)
  $ docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db mongo:latest
  $ docker run -d --network=reddit --network-alias=post ilyahoochie/post:1.0
  $ docker run -d --network=reddit --network-alias=comment ilyahoochie/comment:1.0
  $ docker run -d --network=reddit -p 9292:9292 ilyahoochie/ui:2.0
  ```
* С оставновкой контенеров данные потерялись.

* Добавляем volume и подключаем его к контейнеру с mongo
  ```
  $ docker volume create reddit_db
  ```
  ```
  $ docker kill $(docker ps -q)
  $ docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db -v reddit_db:/data/db mongo:latest
  $ docker run -d --network=reddit --network-alias=post ilyahoochie/post:1.0
  $ docker run -d --network=reddit --network-alias=comment ilyahoochie/comment:1.0
  $ docker run -d --network=reddit -p 9292:9292 ilyahoochie/ui:2.0
  ```

* Перезапускаем контейнеры - ранее оставленный пост оставлся на месте

#### ДЗ №14: Docker: сети, docker-compose

##### Работа с сетью в Docker

* Контейнер с использованием none-драйвера
  ```
  $ docker run -ti --rm --network none joffotron/docker-net-tools -c ifconfig 
  ```
* Контейнер с использованием host-драйвера
  ```
  $ docker run -ti --rm --network host joffotron/docker-net-tools -c ifconfig 
  ```
* Контейнер с использованием bridge-драйвера

* Создание bridge-сети (дефолтный тип драйвера)
  ```
  $ docker network create reddit --driver bridge 
  ```
* Запуск проекта. Контейнеры ссылаются друг на друга по dns именам, прописанным в ENV-переменных в Dockerfile.
  ```
  $ docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db mongo:latest
  $ docker run -d --network=reddit --network-alias=post ilyahoochie/post:1.0
  $ docker run -d --network=reddit --network-alias=comment ilyahoochie/comment:1.0
  $ docker run -d --network=reddit -p 9292:9292 ilyahoochie/ui:1.0
  ```
* Запустим проект в двух  bridge сетях
  ```
  $ docker kill $(docker ps -q)
  ```
* Создаем сети
  ```
  $ docker network create back_net --subnet=10.0.2.0/24
  $ docker network create front_net --subnet=10.0.1.0/24
  ```
* Запуск контейнеров
  ```
  $ docker run -d --network=front_net -p 9292:9292 --name ui ilyahoochie/ui:1.0
  $ docker run -d --network=back_net --name comment ilyahoochie/comment:1.0
  $ docker run -d --network=back_net --name post ilyahoochie/post:1.0
  $ docker run -d --network=back_net --name mongo_db  --network-alias=post_db --network-alias=comment_db mongo:latest 
  ```
* Docker при инициализации контейнера может подключить к нему только 1 сеть. При этом контейнеры из соседних сетей не будут доступны как в DNS, так и для взаимодействия по сети. Поэтому нужно поместить контейнеры post и comment в обе сети.
  ```
  $ docker network connect front_net post
  $ docker network connect front_net comment
  ```
  
##### Docker-compose

* Установка 
  ```
  $ pip install docker-compose
  ```
* Описание проекта добавляем в src/docker-compose.yml

* Добавляем переменную окружения
  ```
  $ export USERNAME=ilyahoochie
  ```
* Останавливаем старые контейнеры и запускаем новые при помощи docker-compose
  ```
  $ docker kill $(docker ps -q) 
  $ docker-compose up -d
  $ docker-compose ps
  ```

* Изменен src/docker-compose.yml под кейс с множеством сетей, сетевых алиасов

* Параметризированы переменные, значения внесены в файл .env

* Базовое имя проекта устанавливается равным текущей директории, изменить это поведение можно через параметр -p
  ```
    -p, --project-name NAME     Specify an alternate project name
                                (default: directory name)
  ```
* Пример
  ```
  $ docker-compose -p reddit up -d
  ```
#### ДЗ №15: Устройство Gitlab CI. Построение процесса непрерывной поставки

##### Инсталляция Gitlab CI

* Новую виртуальную машину в GCP создадим при помощи Terraform. Конфигуация описана в gitlab-ci/terraform.

* Docker и Docker-compose на созданных хост установим при помощи Ansible. Конфиграци описана в gitlab-ci/ansible.

* Подготовка окружения на новом хосте
  ```
  $ mkdir -p /srv/gitlab/config /srv/gitlab/data /srv/gitlab/logs
  $ cd /srv/gitlab/
  $ touch docker-compose.yml
  ```
* Заполняем docker-compose.yml по шаблону https://docs.gitlab.com/omnibus/docker/README.html#install-gitlab-using-docker-compose и устаавливаем github-ci на сервер
  ```
  /srv/gitlab$ docker-compose up -d
  ```
* Зоздаем группу и проект

* Добавляем remote в репозиторий
  ```
  $ git remote add gitlab http://35.205.116.141/homework/example.git 
  $ git push gitlab gitlab-ci-1
  ```
* Добавляем файл .gitlab-ci.yml в репозиторий для определения CI/CD pipline
  ```
  $ git add .gitlab-ci.yml
  $ git commit -m 'add pipeline definition'
  $ git push gitlab gitlab-ci-1
  ```

* Регистрируем и запускаем Runner

* На GCE хосте выполняем
  ```
  $ docker run -d --name gitlab-runner --restart always \
  -v /srv/gitlab-runner/config:/etc/gitlab-runner \
  -v /var/run/docker.sock:/var/run/docker.sock \
  gitlab/gitlab-runner:latest
  ```

* Регистрируем Runner
  ```
  $ docker exec -it gitlab-runner gitlab-runner register --run-untagged --locked=false
  ```
* Добавим исходный код reddit в репозиторий
  ```
  $ git clone https://github.com/express42/reddit.git && rm -rf ./reddit/.git
  $ git add reddit/
  $ git commit -m “Add reddit app”
  $ git push gitlab gitlab-ci-1
  ```
* Меняем описание пайплайна в .gitlab-ci.yml для тестирования приложения

* Добавляем файл теста simpletest.rb

* Добавляем библиотеку rack-test в reddit/Gemfile


##### Разделение на окружения

* Изменяем .gitlab-ci.yml  для dev окружения
  ```
  deploy_dev_job:
    stage: review
    script:
      - echo 'Deploy'
    environment:
      name: dev
      url: http://dev.example.com
  ```

* Изменяем .gitlab-ci.yml  для stg и prod окружений
  ```
  staging:
    stage: stage
    when: manual
    only:
      - /^\d+\.\d+\.\d+/ 
    script:
      - echo 'Deploy'
    environment:
      name: stage
      url: https://beta.example.com

  production:
    stage: production
    when: manual
    only:
      - /^\d+\.\d+\.\d+/ 
    script:
      - echo 'Deploy'
    environment:
      name: production
      url: https://example.com
  ```

* Изменение, помеченное тэгом в git запустит полный пайплайн
  ```
  $ git commit -a -m ‘#4 add logout button to profile page’
  $ git tag 2.4.10
  $ git push gitlab gitlab-ci-1 --tags
  ```
* Динамическое окружение задано при помощи переменных в .gitlab-ci.yml. На каждую ветку в git отличную от master
Gitlab CI будет определять новое окружение.
