#!/usr/bin/env bash

EXOLASTIC_KEYFILE=`cat ../terraform/terraform.tfvars | grep private_key_file | cut -d"\"" -f 2`

if [ ${#EXOLASTIC_KEYFILE} -lt 1 ]; then
    echo "EXOLASTIC_KEYFILE env variable is not set. Exiting.";
    exit 1;
fi

if [ "$#" -gt 2 ]; then
    echo "$0: Script usage: playbook_script.sh [deploy|service] [optional playbook tag]";
    exit 1;
fi

playbook_mode=$1
playbook_tag=$2

# Set up playbook file used
if [ "${playbook_mode}" == "deploy" ]; then
    # Fetch Ansible roles
    ansible-galaxy install jtyr.ulimit --force -p playbooks/roles
    ansible-galaxy install elastic.elasticsearch,6.6.0 --force -p playbooks/roles
    playbook_file="playbooks/deploy.yml"
elif [ "${playbook_mode}" == "kibana" ]; then
    # Fetch Ansible roles
    ansible-galaxy install jtyr.config_encoder_filters --force -p playbooks/roles
    ansible-galaxy install jtyr.kibana --force -p playbooks/roles
    sed -i "s/config_encoder_filters/jtyr.config_encoder_filters/g" playbooks/roles/jtyr.kibana/meta/main.yml
    playbook_file="playbooks/kibana.yml"
elif [ "${playbook_mode}" == "service" ]; then
    playbook_file="playbooks/service.yml"
else
    echo "Unknown Ansible playbook mode: ${playbook_mode}. Please choose one of following: [deploy|service]"
    exit 1;
fi

# Run Ansible playbook
if [ ${#playbook_tag} -lt 1 ]; then
    ansible-playbook -i inventory ${playbook_file} --private-key="${EXOLASTIC_KEYFILE}"
else
    ansible-playbook -i inventory ${playbook_file} --private-key="${EXOLASTIC_KEYFILE}" -t "${playbook_tag}"
fi
