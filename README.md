# ihoochie_microservices [![Build Status](https://travis-ci.com/otus-devops-2019-05/ihoochie_microservices.svg?branch=master)](https://travis-ci.com/otus-devops-2019-05/ihoochie_microservices)

[ДЗ №12 Технология контейнеризации. Введение в Docker](#дз-12-технология-контейнеризации-введение-в-docker)
* [Docker-образы и контейнеры](#docker-образы-и-контейнеры)
* [Задание со * 1](#задание-со-звездочкой-1-отличие-образа-от-контейнера)
* [Docker hub](#docker-hub)
* [Задание со * 2](#задание-со-звездочкой-2-создание-инстансов-с-утавноленным-докером-и-запущенным-контейнером-с-приложением)



#### ДЗ №12 Технология контейнеризации. Введение в Docker

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

* Открыти доступупа к порту 9292
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
