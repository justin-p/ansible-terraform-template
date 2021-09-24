# Ansible Terraform Template

Template that uses Ansible to call terraform to create a VM. Then Ansible uses the Terraform to provision the created VM. Currently this project supports 2 cloud providers, `digitalocean` and `hetzner`. Each cloud provider has 1 terraform project to setup a singular VM.

Intended to be a quick 'grab and go' for cases where:

- You quickly need a cloud VM with some barebones config.
- You want to test/build a Ansible playbook/role against a cloud provider VM.

## Setup

### Ansible

Copy the example `template_info.example.yml` file and add the edit the information as you see fit.

```bash
cp ansible/defaults/template_info.example.yml ansible/defaults/template_info.yml 
```

Copy the example `secrets.example.yml` file and add the your cloud provder API key('s).

```bash
cp ansible/defaults/secrets.example.yml ansible/defaults/secrets.yml 
```

Now you can run:

- `ansible-playbook ansible/main.yml --tags=create` to create, bootstrap and apply your task to the server created server (if any are defined in `ansible/tasks/main.yml`).
- `ansible-playbook ansible/main.yml` to apply your task to the server (if any are defined in `ansible/tasks/main.yml`).
- `ansible-playbook ansible/main.yml --tags=destroy` to destroy the server at the current configured cloud provider.

**NOTE:** The template is *not* smart enough to know if you have switch cloud providers between runs and not have removed the previous deployed VM. Don't blame me if you get large bills because you forgot that you had a VM deployed :) Make sure to remove the VM before switching providers if you tent to forget things.

#### Your extra tasks

If you require additional tasks to be ran after initial configuration you can add those into `ansible/tasks/main.yml`.

If your tasks require additional roles you can let them be automatically installed by adding them to the `ansible/files/requirements.yml` file. This will install theses roles to the `ansible/roles` folder.

If you want to setup variables for your tasks add these to the `ansible/defaults/main.yml` file.

### Terraform development (optional)

If you want to work on the terraform project files themselves outside of ansible, create a copy of the `terraform.tfvars.example` file and fill in the token variable with your API key.

```bash
cp terraform.tfvars.example terraform.tfvars 
```

**NOTE:** The ansible playbook also creates `terraform.tfvars ` files for you. In that case just verify if the API keys match.

Then `cd` to the terraform project folder and run terraform as usual.

```bash
terraform init
terraform apply
terraform destroy
```

## License

MIT

## Authors

Justin Perdok ([@justin-p](https://github.com/justin-p/))

## Contributing

Feel free to open issues, contribute and submit your Pull Requests. You can also ping me on Twitter ([@JustinPerdok](https://twitter.com/JustinPerdok)).
