# Ansible Terraform Template

Template that uses Ansible to call terraform and create a VM, then Ansible uses the output given by Terraform to dynamically built its inventory to provision the created VM.
Currently this project supports 2 cloud providers, `digitalocean` and `hetzner`.

Intended to be a quick 'grab and go' for cases where:

- You quickly need a cloud VM with some barebones config.
- You want to test/build a Ansible playbook/role against a cloud provider VM.

This can also be used as a template/basis for cases where:

- You want to build a project that can spin up specific set of infra whenever you need it.

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

**NOTE:** The template is *not* smart enough to know if you have switch cloud providers between runs and not have removed the previous deployed VM. It only removes VMs on cloud providers that are *currently* configured in the `host_list` variable. Don't blame me if you get large bills because you forgot that you had a VM deployed :) Make sure to remove the VMs before you remove/disable a provider in the `host_list` variable.

#### Your extra tasks

If you require additional tasks to be ran after initial configuration you can add those into `ansible/tasks/main.yml`.

If your tasks require additional roles you can let them be automatically installed by adding them to the `ansible/files/requirements.yml` file. This will install theses roles to the `ansible/roles` folder.

If you want to setup variables for your tasks add these to the `ansible/defaults/main.yml` file.

#### Setting up the host_list

By setting up a `host_list` variable in the `template_info.yml`-file you can define the following things:

- How many hosts should be deployed.
- How a host should be deployed.
- Where the host should be deployed.
- To what ansible inventory group the host should be added.

##### Example 1

The example below defines one host on digitalocean. In this case we want to deploy a simple webserver.

```yaml
host_list: {
  digitalocean: [
    { "name": "web01",
      "tag": "[\"web\"]"
    }
  ]
}
```

Since not all terraform values are defined for the VM in the `host_list` variable, the missing values will use their default settings as show below:

```terraform
locals {
  servers = defaults(var.servers, {
    size               = "s-1vcpu-1gb"
    image              = "ubuntu-20-04-x64"
    region             = "ams3"
    monitoring         = false
    private_networking = false
  })
}
```

Terraform also adds tags/lables to the deployed hosts on the cloud provider. In this case we added a tag to `web01` called `web`. These tags/lables are used by Ansible to add the specific host to an inventory groups that matches the tag/label. Meaning you can easily add host to specific groups while the inventory is still dynamically build based off Terraform output.

Thus in our ansible code we define a play against the the ansible group `web` to configure our web host.

```yaml
---
- hosts: web
   vars:
     ansible_user: "{{ root_username }}"
     ansible_ssh_private_key_file: "{{ root_private_key_path }}"
 
   tasks:
     - name: Configure our webhosts
       ansible.builtin.import_tasks: tasks/web_tasks.yml
       tags: always
```

##### Example 2

The example below defines two hosts on digitalocean. We decided that one webserver was not enough, so we added a second one.

```yaml
host_list: {
  digitalocean: [
    { "name": "web01",
      "tag": "[\"web\"]"
    },
    { "name": "web02",
      "tag": "[\"web\"]"
    }    
  ]
}
```

Since we have not defined any other values on both the hosts the missing values will still use their default settings as show below: 

```terraform
locals {
  servers = defaults(var.servers, {
    size               = "s-1vcpu-1gb"
    image              = "ubuntu-20-04-x64"
    region             = "ams3"
    monitoring         = false
    private_networking = false
  })
}
```

Since both hosts are added to the web group in our inventory we don't need to update our play.

```yaml
---
- hosts: web
   vars:
     ansible_user: "{{ root_username }}"
     ansible_ssh_private_key_file: "{{ root_private_key_path }}"
 
   tasks:
     - name: Configure our webhosts
       ansible.builtin.import_tasks: tasks/web_tasks.yml
       tags: always
```

##### Example 3

The example below defines three hosts on digitalocean. We decided that one our website needed a database, and thus a database server, so we defined a third server in our `host_list`. Since we expect our DB to use more resources we changed set its size to `s-2vcpu-4g`. We also moved the webhost `web01` to a other digitalocean datacenter.

```yaml
host_list: {
  digitalocean: [
    { "name": "web01",
      "tag": "[\"web\"]"
      "region": "lon1"
    },
    { "name": "web02",
      "tag": "[\"web\"]"
    },
    { "name": "db01",
      "tag": "[\"db\"]",
      "size": "s-2vcpu-4gb"
    }
  ]
}
```

All the other values that are missing on each host will again use their default settings as show below: 

```terraform
locals {
  servers = defaults(var.servers, {
    size               = "s-1vcpu-1gb"
    image              = "ubuntu-20-04-x64"
    region             = "ams3"
    monitoring         = false
    private_networking = false
  })
}
```

In our ansible code we would define a additional play against the the ansible group `db` to configure our database host.

```yaml
---
- hosts: web
   vars:
     ansible_user: "{{ root_username }}"
     ansible_ssh_private_key_file: "{{ root_private_key_path }}"
 
   tasks:
     - name: Configure our webhosts
       ansible.builtin.import_tasks: tasks/web_tasks.yml
       tags: always

- hosts: db
   vars:
     ansible_user: "{{ root_username }}"
     ansible_ssh_private_key_file: "{{ root_private_key_path }}"
 
   tasks:
     - name: Configure our database hosts
       ansible.builtin.import_tasks: tasks/database_tasks.yml
       tags: always
```

##### Example 4

The example below defines five hosts split on two different cloud providers. Our previous stack on digitalocean and two additional mail servers on hetzner.

```yaml
host_list: {
  digitalocean: [
    { "name": "web01",
      "tag": "[\"web\"]"
      "region": "lon1"
    },
    { "name": "web02",
      "tag": "[\"web\"]"
    },
    { "name": "db01",
      "tag": "[\"db\"]",
      "size": "s-2vcpu-4gb"
    }
  ],
  hetzner: [
    { "name": "mail01",
      "labels": "{mail = \"\"}"
    },
    { "name": "mail02",
      "labels": "{mail = \"\"}"
    }    
  ]
}
```

All the missing values will again use their default settings as show below: 

```terraform
## digitalocean
locals {
  servers = defaults(var.servers, {
    size               = "s-1vcpu-1gb"
    image              = "ubuntu-20-04-x64"
    region             = "ams3"
    monitoring         = false
    private_networking = false
  })
}

## hetzner
locals {
  servers = defaults(var.servers, {
    server_type = "cx11"
    image       = "ubuntu-20.04"
    name        = "testvm"
    location    = "nbg1"
    backups     = false
  })
}
```

In our ansible code we would define a additional play against the the ansible group `mail` to configure our mail servers.

```yaml
---
- hosts: web
   vars:
     ansible_user: "{{ root_username }}"
     ansible_ssh_private_key_file: "{{ root_private_key_path }}"
 
   tasks:
     - name: Configure our webhosts
       ansible.builtin.import_tasks: tasks/web_tasks.yml
       tags: always

- hosts: db
   vars:
     ansible_user: "{{ root_username }}"
     ansible_ssh_private_key_file: "{{ root_private_key_path }}"
 
   tasks:
     - name: Configure our database hosts
       ansible.builtin.import_tasks: tasks/database_tasks.yml
       tags: always

- hosts: mail
   vars:
     ansible_user: "{{ root_username }}"
     ansible_ssh_private_key_file: "{{ root_private_key_path }}"
 
   tasks:
     - name: Configure our mail hosts
       ansible.builtin.import_tasks: tasks/mail_tasks.yml
       tags: always       
```

### Terraform (optional)

If you want to work on the terraform project files themselves outside of ansible, create a copy of the `terraform.tfvars.example` file and fill in the token variable with your API key.

```bash
cp terraform.tfvars.example terraform.tfvars 
```

**NOTE:** The ansible playbook also creates/overwrites `terraform.tfvars` files for you. In that case just verify if the API keys match and setup the tfvars file as you would like.

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
