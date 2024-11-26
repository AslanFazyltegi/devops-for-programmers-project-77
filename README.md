### Hexlet tests and linter status:
[![Actions Status](https://github.com/AslanFazyltegi/devops-for-programmers-project-77/actions/workflows/hexlet-check.yml/badge.svg)](https://github.com/AslanFazyltegi/devops-for-programmers-project-77/actions)



# Инструкция по запуску инфраструктуры и приложения

Данный проект использует Terraform для развертывания инфраструктуры и Ansible для установки приложения на виртуальные машины.

## Make команды

### `make create_structure`
Эта команда запускает Terraform для создания основной структуры инфраструктуры в облаке, включая все необходимые ресурсы (например, сети, балансировщики и т.д.).

Пример:
```
make create_structure
```

### `make install_app`
Запускает Ansible для установки и настройки приложения на виртуальных машинах. Для работы команды требуется правильно настроенный инвентарь и playbook.

Пример:
```
make install_app
```

### `create_balancer`
Эта команда использует Terraform для создания балансировщика нагрузки (ALB) для распределения трафика между сервисами.

Пример:
```
make create_balancer
```

### `make deploy_all`
Запускает весь процесс развертывания инфраструктуры и приложения. Сначала создается структура облака с помощью `create_structure`, затем происходит установка приложения с помощью `install_app`, и в завершение создается балансировщик нагрузки с помощью `create_balancer`.

Пример:
```
make deploy_all
```

### `make destroy_all`
Удаляет все ресурсы, развернутые с помощью Terraform и Ansible. Эта команда очищает вашу инфраструктуру и приложение.

Пример:
```
make destroy_all
```

## Приложение

Приложение развернуто по адресу: [hexletlab.adizit.kz](http://hexletlab.adizit.kz)

Для работы с проектом потребуется доступ к облачному провайдеру и настроенные ключи доступа для Terraform и Ansible. Данный проект выполнен в рамках обучения на hexlet.ru

