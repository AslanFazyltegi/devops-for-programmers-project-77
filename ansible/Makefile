install-requirements:
	ansible-galaxy install -r requirements.yml


ansible-prepare:
	ansible-playbook -i inventory.ini playbook.yml --tags prepare --user=admin --private-key=/root/hexlet/hexletyandexubuntu1sshrsa --vault-password-file vault-password
ansible-deploy:
	ansible-playbook -i inventory.ini playbook.yml --tags deploy --user=admin --private-key=/root/hexlet/hexletyandexubuntu1sshrsa --vault-password-file vault-password
ansible-datadog:
	ansible-playbook -i inventory.ini playbook.yml --tags datadog --user=admin --private-key=/root/hexlet/hexletyandexubuntu1sshrsa --vault-password-file vault-password
ansible-full:
	ansible-playbook -i inventory.ini playbook.yml --user=admin --private-key=/root/hexlet/hexletyandexubuntu1sshrsa --vault-password-file vault-password
