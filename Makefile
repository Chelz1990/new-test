# ---------------------------------------------------------------------------

# Make-Script for plan-apply-destroy for three different zones:

pull:
	git pull

init: pull
	terraform init 

validate: init
	terraform validate 

plan-us-e:
	terraform plan -var="location=eastus"

plan-eu-w: 
	terraform plan -var="location=westeurope"

plan-asi-s:
	terraform plan -var="location=southeastasia"

apply-us-e:
	terraform apply --auto-approve -var="location=eastus"

apply-eu-w:
	terraform apply --auto-approve -var="location=westeurope"

apply-asi-s:
	terraform apply --auto-approve -var="location=southeastasia"

destroy-us-e:
	terraform destroy --auto-approve -var="location=eastus"

destroy-eu-w:
	terraform destroy --auto-approve -var="location=westeurope"

destroy-asi-s:
	terraform destroy --auto-approve -var="location=southeastasia"

cleanup:
	find / -type d  -name ".terraform" -exec rm -rf {} \;

# ---------------------------------------------------------------------------