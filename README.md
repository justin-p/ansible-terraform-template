# Ansible Terraform Template

Template that uses Ansible to call terraform to create a VM. Then Ansible uses the Terraform to provision the created VM. Currently this project has 1 terraform project to setup a singular DigitalOcean droplet.

Intended to be a quick 'grab and go' for cases where:

- You quickly need a DigitalOcean droplet with some barebones config.
- You want to test/build a Ansible playbook/role against a DigitalOcean droplet.

## Setup

### Ansible

Copy the example template_info var file and add the edit the information as you see fit.

```bash
cp ansible/defaults/template_info.example.yml ansible/defaults/template_info.yml 
```

Copy the example secrets var file and add the your digitalocean API key.

```bash
cp ansible/defaults/secrets.example.yml ansible/defaults/secrets.yml 
```

Now you can run:

- `ansible-playbook ansible/main.yml` to create and setup the server.
- `ansible-playbook ansible/main.yml --tags=destroy` to remove the server.

#### Your extra tasks

If you require additional tasks to be ran after initial configuration you can add those into `ansible/tasks/main.yml`.

If your tasks require additional roles you can let them be automatically installed by adding them to the `ansible/files/requirements.yml` file. This will install theses roles to the `ansible/roles` folder.

If you want to setup variables for your tasks add these to the `ansible/defaults/main.yml` file.

### Terraform development (optional)

If you want to work on the terraform project files themselves outside of ansible, create a copy of the `terraform.tfvars.example` file and fill in the `do_token` with your digitalocean API key.

```bash
cp terraform/digitalocean/single_vm/terraform.tfvars.example terraform/digitalocean/single_vm/terraform.tfvars 
```

Then `cd` to the terraform project folder and run terraform as usual.

```bash
cd terraform/digitalocean/single_vm/
terraform init
```

## License

MIT

## Authors

Justin Perdok ([@justin-p](https://github.com/justin-p/))

## Contributing

Feel free to open issues, contribute and submit your Pull Requests. You can also ping me on Twitter ([@JustinPerdok](https://twitter.com/JustinPerdok)).
