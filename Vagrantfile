# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# Three-tier movie-viewer environment built from the Packer base box.
# Vagrant only creates the machines and the host-only network; Ansible is run
# separately (`cd ansible && ansible-playbook site.yml`), see README.md.
#
# Every value can be overridden from the environment, e.g.:
#   BASE_BOX=my-box DATABASE_IP=10.10.10.10 vagrant up --no-provision
# Keep the *_IP values in sync with ansible/inventory.ini.

BOX_NAME  = ENV.fetch("BASE_BOX", "base-ubuntu")
SSH_USER  = ENV.fetch("SSH_USER", "vagrant")
SSH_KEY   = ENV.fetch("SSH_KEY", File.expand_path("keys/id_ed25519", File.dirname(__FILE__)))
VM_MEMORY = ENV.fetch("VM_MEMORY", "1024").to_i
VM_CPUS   = ENV.fetch("VM_CPUS", "1").to_i

Vagrant.configure("2") do |config|
  config.vm.box = BOX_NAME

  # The base image only accepts the project key and password auth is disabled
  # (see packer/http/user-data.tmpl). Reuse that key and never replace it.
  config.ssh.username = SSH_USER
  config.ssh.private_key_path = SSH_KEY
  config.ssh.insert_key = false

  # Guest Additions are disabled in the base image.
  config.vm.synced_folder ".", "/vagrant", disabled: true

  nodes = {
    "database" => ENV.fetch("DATABASE_IP", "192.168.56.10"),
    "backend"  => ENV.fetch("BACKEND_IP",  "192.168.56.11"),
    "frontend" => ENV.fetch("FRONTEND_IP", "192.168.56.12"),
  }

  nodes.each do |name, ip|
    config.vm.define name do |node|
      node.vm.hostname = name
      node.vm.network "private_network", ip: ip

      node.vm.provider "virtualbox" do |vb|
        vb.name = name
        vb.memory = VM_MEMORY
        vb.cpus = VM_CPUS
      end
    end
  end
end
