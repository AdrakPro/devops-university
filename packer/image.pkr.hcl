packer {
  required_plugins {
    virtualbox = {
      version = ">= 1.1.5"
      source  = "github.com/hashicorp/virtualbox"
    }
    vagrant = {
      version = ">= 1.1.7"
      source  = "github.com/hashicorp/vagrant"
    }
  }
}

variable "iso_url" {
  type        = string
  description = "Path or URL of the Ubuntu Server ISO."
  default     = "../../Downloads/ubuntu-24.04.5-live-server-amd64.iso"
}

variable "iso_checksum" {
  type        = string
  description = "SHA-256 of the Ubuntu 24.04.5 server ISO."
  default     = "sha256:97f3d7ffb032c3eb3b23d2c8be9cc76e60c2c1f2c0146ba5ba9fe01cafae0fd8"
}

variable "headless" {
  type        = bool
  description = "Run VirtualBox without a window."
  default     = false
}

variable "http_port" {
  type        = number
  description = "Port the Packer HTTP server serves the autoinstall data on."
  default     = 18080
}

source "virtualbox-iso" "base" {
  vm_name                = "base-ubuntu"
  iso_url                = var.iso_url
  iso_checksum           = var.iso_checksum
  guest_os_type          = "Ubuntu_64"
  disk_size              = 20480
  headless               = var.headless
  http_directory         = "http"
  http_port_min          = var.http_port
  http_port_max          = var.http_port
  ssh_username           = "vagrant"
  ssh_private_key_file   = "../keys/id_ed25519"
  ssh_timeout            = "60m"
  ssh_handshake_attempts = 100
  shutdown_command       = "sudo shutdown -P now"
  shutdown_timeout       = "15m"
  guest_additions_mode   = "disable"
  boot_wait              = "10s"
  boot_keygroup_interval = "250ms"

  # Open the GRUB console with `c`, then boot the live kernel with the
  # autoinstall arguments attached. `autoinstall` skips the confirmation
  # prompt; `ds=nocloud-net` tells cloud-init to fetch user-data/meta-data
  # from the Packer HTTP server (10.0.2.2:<http_port>). `\;` escapes GRUB's
  # command separator so the kernel receives `ds=nocloud-net;s=http://...`
  # literally. boot_wait is generous so the `c` lands while the GRUB menu
  # (30s timeout) is still on screen even on a slow first boot.
  boot_command = [
    "<wait5>",
    "c",
    "<wait2>",
    "linux /casper/vmlinuz autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---",
    "<enter>",
    "<wait>",
    "initrd /casper/initrd",
    "<enter>",
    "<wait>",
    "boot",
    "<enter>"
  ]
  vboxmanage = [
    ["modifyvm", "{{ .Name }}", "--memory", "2048"],
    ["modifyvm", "{{ .Name }}", "--cpus", "2"],
    ["modifyvm", "{{ .Name }}", "--nic1", "nat"],
    ["modifyvm", "{{ .Name }}", "--audio", "none"],
    # VirtualBox defaults to DVD before disk. Boot disk first so that, after
    # the install reboots, the VM boots the installed system instead of the
    # live ISO again (which has no SSH server and stalls Packer).
    ["modifyvm", "{{ .Name }}", "--boot1", "disk"],
    ["modifyvm", "{{ .Name }}", "--boot2", "dvd"],
  ]
}

build {
  sources = ["source.virtualbox-iso.base"]

  provisioner "shell" {
    inline = [
      "truncate -s 0 /etc/machine-id",
      "rm -rf /tmp/* /var/tmp/*",
      "systemctl enable --now ssh",
      "sync",
    ]
  }

  post-processor "vagrant" {
    output = "base-ubuntu.box"
  }
}
