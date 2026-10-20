# DevOps University — VM pipeline

This repository builds a small three-tier environment from one Packer base
image, launches three VMs with Vagrant, and configures them with Ansible.

| VM | Private IP | Role |
| --- | --- | --- |
| `database` | `192.168.56.10` | PostgreSQL |
| `backend` | `192.168.56.11` | FastAPI + uvicorn |
| `frontend` | `192.168.56.12` | nginx + React app |

The base image is built from **Ubuntu 24.04.5 LTS Server** (the local ISO in
`~/Downloads`) using the standard Subiquity `autoinstall` flow. The application is the
movie viewer under `src/`.

The full design is in
[`docs/IMPLEMENTATION_PLAN.md`](docs/IMPLEMENTATION_PLAN.md).

## Quick start

```bash
make keys        # generate the project SSH key (gitignored)
make validate    # validate the Packer template
make build       # build packer/base-ubuntu.box
make box         # register it with Vagrant
vagrant up       # create and provision the three VMs
make verify      # run the end-to-end checks
```

## Layout

- `packer/` — base image template and autoinstall data.
- `ansible/` — inventory, site playbook, and the four roles.
- `scripts/` — toolchain, key generation, build, and verification helpers.
- `src/` — the existing FastAPI/React/PostgreSQL application.

## Teardown

```bash
vagrant destroy -f
```
