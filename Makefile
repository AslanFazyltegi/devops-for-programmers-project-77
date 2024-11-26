create_structure:
	make -C terraform tf-create-cloud-structure

install_app:
	make -C ansible ansible-full

create_balancer:
	make -C terraform tf-create-cloud-alb

deploy_all:
	make -C terraform tf-create-cloud-structure
        make -C terraform tf-get-vm-ips
	make -C ansible ansible-full
	make -C terraform tf-create-cloud-alb

destroy_all:
	make -C terraform tf-destroy
