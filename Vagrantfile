BOX_NAME  = ENV.fetch("BASE_BOX", "base-ubuntu")
SSH_USER  = ENV.fetch("SSH_USER", "vagrant")
SSH_KEY   = ENV.fetch("SSH_KEY", File.expand_path("keys/id_ed25519", File.dirname(__FILE__)))
VM_MEMORY = ENV.fetch("VM_MEMORY", "1024").to_i
VM_CPUS   = ENV.fetch("VM_CPUS", "1").to_i

Vagrant.configure("2") do |config|
  config.vm.box = BOX_NAME

  # packer/http/user-data.tmpl
  config.ssh.username = SSH_USER
  config.ssh.private_key_path = SSH_KEY
  config.ssh.insert_key = false

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
