# Ubuntu VM pipeline
#
# One Packer base image, three Vagrant VMs, Ansible per-role provisioning.
# See docs/IMPLEMENTATION_PLAN.md for the full design and commit checkpoints.

SHELL := /bin/bash

ISO ?= $(HOME)/Downloads/ubuntu-24.04.5-live-server-amd64.iso
KEY := keys/id_ed25519
BOX := packer/base-ubuntu.box
ANSIBLE_ARGS ?=

.PHONY: help keys init validate build box up provision verify destroy clean

help:
	@printf '%s\n' \
		'Targets:' \
		'  make keys       Generate keys/id_ed25519 if missing' \
		'  make init       Install Packer plugins' \
		'  make validate   Validate the Packer template' \
		'  make build      Build $(BOX)' \
		'  make box        Register the box with Vagrant' \
		'  make up         Start the three VMs (no provisioning)' \
		'  make provision  Configure the VMs with Ansible' \
		'  make verify     Run the end-to-end checks' \
		'  make destroy    Remove the three VMs' \
		'  make clean      Remove local build and Vagrant state' \
		'' \
		'Override the ISO with: make build ISO=/path/to/ubuntu.iso' \
		'Extra Ansible arguments: make provision ANSIBLE_ARGS="-e db_password=..."'

keys:
	./scripts/generate-keys.sh

init:
	cd packer && packer init .

validate: keys
	cd packer && packer validate -var "iso_url=$(ISO)" .

build: keys
	./scripts/build-box.sh "$(ISO)"

box: $(BOX)
	vagrant box add --force base-ubuntu $(BOX)

up: box
	vagrant up --no-provision

provision:
	cd ansible && ansible-playbook site.yml $(ANSIBLE_ARGS)

verify:
	./scripts/verify.sh $(ANSIBLE_ARGS)

destroy:
	vagrant destroy -f

clean:
	rm -rf packer/output packer/packer_cache .vagrant
