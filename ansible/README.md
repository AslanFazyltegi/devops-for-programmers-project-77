### Hexlet tests and linter status:
[![Actions Status](https://github.com/AslanFazyltegi/devops-for-programmers-project-76/actions/workflows/hexlet-check.yml/badge.svg)](https://github.com/AslanFazyltegi/devops-for-programmers-project-76/actions)


# Проект DevOps: Подготовка серверов и деплой

## Описание
Этот проект автоматизирует подготовку серверов для развертывания приложений с использованием Ansible. Также он включает инструкции по установке зависимостей и развертыванию Docker-контейнеров.

---

## Подготовка инфраструктуры
   Для начала создадим необходимую инфраструктуру через интерфейс облачного провайдера. Нам потребуются:

	Два сервера
	Балансировщик нагрузки
	Кластер базы данных

   �Выполнить все шаги согласно https://yandex.cloud/ru/docs/application-load-balancer/tutorials/virtual-hosting

## Предварительные требования
Перед началом убедитесь, что выполнены следующие условия:

1. Установлен [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html).
2.  
  git clone https://github.com/AslanFazyltegi/devops-for-programmers-project-76.git

  cd devops-for-programmers-project-76

---

## Подготовка серверов

   Запустите плейбук для подготовки серверов:

    ansible-playbook -i inventory.ini playbook-prepare.yml

	или

    cd devops-for-programmers-project-76
    make prepare 


##   Деплой проекта


	ansible-playbook -i inventory.ini playbook-deploy.yml --tags deploy --vault-password-file vault-password

или

	make deploy


##  Ссылка проекта

	https://hexletlab.adizit.kz/
