# Ansible Terraform Template

Template that uses Ansible to call terraform and create a VM, then Ansible uses the output given by Terraform to dynamically built its inventory to provision the created VM.
Currently this project supports 2 cloud providers, `digitalocean` and `hetzner`.

Intended to be a quick 'grab and go' for cases where:

- You quickly need a cloud VM with some barebones config.
- You want to test/build a Ansible playbook/role against a cloud provider.

This can also be used as a template for cases where:

- You want to build a project that can consistently spin up and configure the same specific set of infrastructure whenever you need it.

## Setup

### Ansible

Copy the example `template_info.example.yml` file and add the edit the information as you see fit.

```bash
cp ansible/defaults/template_info.example.yml ansible/defaults/template_info.yml 
```

Copy the example `secrets.example.yml` file and add the your cloud provider API key('s).

```bash
cp ansible/defaults/secrets.example.yml ansible/defaults/secrets.yml 
```

Now you can run:

- `ansible-playbook ansible/main.yml --tags=create` to create the infrastructure, install ansible roles locally, bootstrap the created servers and apply your task (if any are defined in `ansible/tasks/main.yml`).
- `ansible-playbook ansible/main.yml` to only apply your task to the server (if any are defined in `ansible/tasks/main.yml`).
- `ansible-playbook ansible/main.yml --tags=destroy` to destroy the infrastructure deployed by terraform.

Other additional tags are:

- `ansible-playbook ansible/main.yml --tags=tfvars` to only create the `terraform.tfvars` file. Useful if you want to work on the [Terraform code](#terraform-optional).
- `ansible-playbook ansible/main.yml --tags=roles` to only instal ansible roles locally.
- `ansible-playbook ansible/main.yml --tags=bootstrap` to only run the bootstrap tasks.

**NOTE:** The template is smart enough to know if you made changes to the infrastructure variable (`host_list`). It only keeps VMs on cloud providers that are *currently* configured in the `host_list` variable. VMs that are no longer listed in the `host_list` variable are automatically destroyed and new ones will automatically be created. It will however *not* configure the new servers with the bootstrap playbook if you did not supply the `create` or the `bootstrap` tag on the `ansible-playbook` command.

#### Ansible Vault (Optional)

To avoid having clear text API tokens linger on disk you can encrypt the `ansible/defaults/secrets.yml` with `ansible-vault`. The following example will allow you to setup a passphrase before you are able to use `ansible/defaults/secrets.yml`.

```bash
ansible-vault encrypt ansible/defaults/secrets.yml
```

Then from this point onward I would recommend you add the `--ask-vault-pass` flag to the ansible commands.

```bash
$ ansible-playbook ansible/main.yml --ask-vault-pass --tags=create
Vault password: 
```

If you ever need to edit the API tokens in `ansible/defaults/secrets.yml` you can do so with `ansible-vault edit`.

```bash
ansible-vault edit ansible/defaults/secrets.yml
```

For more information about ansible-vault [click here](https://docs.ansible.com/ansible/latest/user_guide/vault.html#using-encrypted-variables-and-files).

#### Your extra tasks

If you require additional tasks to be ran after initial configuration you can add those directly into `ansible/main.yml` or split them out to separate tasks files such as `ansible/tasks/main.yml`.

**NOTE:** Make sure you add a `when`-statement that prevents other tasks from running. See the examples in [setting up the host_list](#setting-up-the-host_list).

If your tasks require additional roles you can have them be automatically installed by adding them to the `ansible/files/requirements.yml` file. This will install these roles to the `ansible/roles` folder.

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
  digitalocean_servers = defaults(var.digitalocean_servers, {
    size          = "s-1vcpu-1gb"
    image         = "ubuntu-20-04-x64"
    region        = "ams3"
    backups       = false
    monitoring    = false
    ipv6          = false
    resize_disk   = true
    droplet_agent = false
    create_vpc    = true
  })
}
```

Terraform also adds tags/lables to the deployed hosts on the cloud provider. In this case we added a tag to `web01` called `web`. These tags/lables are used by Ansible to add the specific host to an inventory groups that matches the tag/label. Meaning you can easily add host to specific groups while the inventory is still being dynamically build in memory based off Terraform output.

Thus in the ansible code we define a play against the ansible `web` group to configure the web host.

```yaml
---
- hosts: web
  vars_file:
    - "{{ playbook_dir }}/defaults/template_info.yml"
  vars:
    ansible_user: "{{ root_username }}"
    ansible_ssh_private_key_file: "{{ root_private_key_path }}"
 
  tasks:
    - name: Configure our webhosts
      ansible.builtin.import_tasks: tasks/web_tasks.yml
      tags: always
      when:
        - "'tfvars' not in ansible_run_tags"
        - "'destroy' not in ansible_run_tags"
        - "'roles' not in ansible_run_tags"
        - "'bootstrap' not in ansible_run_tags"
        - "'print_inventory' not in ansible_run_tags"
```

**NOTE:** the `when`-statement is added to ensure the template tags work 'as expected'. If you do not add the `when`-statement the `Configure our webhosts` task will run when you supply these tags. A different solution is to replace the `always`-tag on the `Configure our webhosts` task and supply that tag on each run on `ansible-playbook`.

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

Since we have not defined any other values on both the hosts, the missing values will still use their default settings as show below:

```terraform
locals {
  digitalocean_servers = defaults(var.digitalocean_servers, {
    size          = "s-1vcpu-1gb"
    image         = "ubuntu-20-04-x64"
    region        = "ams3"
    backups       = false
    monitoring    = false
    ipv6          = false
    resize_disk   = true
    droplet_agent = false
    create_vpc    = true
  })
}
```

Since both hosts are added to the web group in our inventory we don't need to update our play.

```yaml
---
- hosts: web
  vars_file:
    - "{{ playbook_dir }}/defaults/template_info.yml"

  vars:
    ansible_user: "{{ root_username }}"
    ansible_ssh_private_key_file: "{{ root_private_key_path }}"

  tasks:
    - name: Configure our webhosts
      ansible.builtin.import_tasks: tasks/web_tasks.yml
      tags: always
      when:
        - "'tfvars' not in ansible_run_tags"
        - "'destroy' not in ansible_run_tags"
        - "'roles' not in ansible_run_tags"
        - "'bootstrap' not in ansible_run_tags"
        - "'print_inventory' not in ansible_run_tags"
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
  digitalocean_servers = defaults(var.digitalocean_servers, {
    size          = "s-1vcpu-1gb"
    image         = "ubuntu-20-04-x64"
    region        = "ams3"
    backups       = false
    monitoring    = false
    ipv6          = false
    resize_disk   = true
    droplet_agent = false
    create_vpc    = true
  })
}
```

In the ansible code we would define a additional play against the ansible `db` group to configure the database host.

```yaml
---
- hosts: web
  vars_file:
    - "{{ playbook_dir }}/defaults/template_info.yml"
  vars:
    ansible_user: "{{ root_username }}"
    ansible_ssh_private_key_file: "{{ root_private_key_path }}"
 
  tasks:
    - name: Configure our webhosts
      ansible.builtin.import_tasks: tasks/web_tasks.yml
      tags: always
      when:
        - "'tfvars' not in ansible_run_tags"
        - "'destroy' not in ansible_run_tags"
        - "'roles' not in ansible_run_tags"
        - "'bootstrap' not in ansible_run_tags"
        - "'print_inventory' not in ansible_run_tags"

- hosts: db
  vars_file:
    - "{{ playbook_dir }}/defaults/template_info.yml"
  vars:
    ansible_user: "{{ root_username }}"
    ansible_ssh_private_key_file: "{{ root_private_key_path }}"
 
  tasks:
    - name: Configure our database hosts
      ansible.builtin.import_tasks: tasks/database_tasks.yml
      tags: always
      when:
        - "'tfvars' not in ansible_run_tags"
        - "'destroy' not in ansible_run_tags"
        - "'roles' not in ansible_run_tags"
        - "'bootstrap' not in ansible_run_tags"
        - "'print_inventory' not in ansible_run_tags"
```

##### Example 4

The example below defines five hosts split on two different cloud providers. Our previous stack on digitalocean and two additional mail servers on hetzner.
Here we also set more options on our VMs, such as hostnames, PTR, regions and images.

```yaml
host_list: {
  digitalocean: [
    { "name": "web01",
      "tag": "[\"web\"]"
      "hostname": "web01.example.tld",
      "region": "lon1",
      "image": "debian-11-x64"
    },
    { "name": "web02",
      "tag": "[\"web\"]",
      "hostname": "web02.example.tld",
      "region": "ams1",
      "image": "debian-11-x64"
    },
    { "name": "db01",
      "tag": "[\"db\"]",
      "hostname": "db01.example.tld",
      "size": "s-2vcpu-4gb",
      "region": "ams3",
      "image": "rancheros"
    }
  ],
  hetzner: [
    { "name": "mail01",
      "labels": "{mail = \"\"}",
      "hostname": "mail01.example.tld",
      "ptr": "mail01.example.tld",
      "location": "hel1",
      "image": "fedora-32"
    },
    { "name": "mail02",
      "labels": "{mail = \"\"}",
      "hostname": "mail02.example.tld",
      "ptr": "mail02.example.tld",
      "location": "fsn1",
      "image": "fedora-32"
    }    
  ]
}
```

**NOTE:** Digitalocean PTRs are setup automatically ( by digitalocean themselves ) to match the droplet hostname.

All the missing values will again use their default settings as show below:

```terraform
locals {
  digitalocean_servers = defaults(var.digitalocean_servers, {
    size          = "s-1vcpu-1gb"
    image         = "ubuntu-20-04-x64"
    region        = "ams3"
    backups       = false
    monitoring    = false
    ipv6          = false
    resize_disk   = true
    droplet_agent = false
    create_vpc    = true
  })
}

locals {
  hetzner_servers = defaults(var.hetzner_servers, {
    server_type = "cx11"
    image       = "ubuntu-20.04"
    location    = "nbg1"
    backups     = false
  })
}
```

In the ansible code we define a additional play against the the ansible `mail` group to configure the mail servers.

```yaml
---
- hosts: web
  vars_file:
    - "{{ playbook_dir }}/defaults/template_info.yml"
  vars:
    ansible_user: "{{ root_username }}"
    ansible_ssh_private_key_file: "{{ root_private_key_path }}"
 
  tasks:
    - name: Configure our webhosts
      ansible.builtin.import_tasks: tasks/web_tasks.yml
      tags: always
      when:
        - "'tfvars' not in ansible_run_tags"
        - "'destroy' not in ansible_run_tags"
        - "'roles' not in ansible_run_tags"
        - "'bootstrap' not in ansible_run_tags"
        - "'print_inventory' not in ansible_run_tags"

- hosts: db
  vars_file:
    - "{{ playbook_dir }}/defaults/template_info.yml"
  vars:
    ansible_user: "{{ root_username }}"
    ansible_ssh_private_key_file: "{{ root_private_key_path }}"
 
  tasks:
    - name: Configure our database hosts
      ansible.builtin.import_tasks: tasks/database_tasks.yml
      tags: always
      when:
        - "'tfvars' not in ansible_run_tags"
        - "'destroy' not in ansible_run_tags"
        - "'roles' not in ansible_run_tags"
        - "'bootstrap' not in ansible_run_tags"
        - "'print_inventory' not in ansible_run_tags"

- hosts: mail
  vars_file:
    - "{{ playbook_dir }}/defaults/template_info.yml"
  vars:
    ansible_user: "{{ root_username }}"
    ansible_ssh_private_key_file: "{{ root_private_key_path }}"
 
  tasks:
    - name: Configure our mail hosts
      ansible.builtin.import_tasks: tasks/mail_tasks.yml
      tags: always
      when:
        - "'tfvars' not in ansible_run_tags"
        - "'destroy' not in ansible_run_tags"
        - "'roles' not in ansible_run_tags"
        - "'bootstrap' not in ansible_run_tags"
        - "'print_inventory' not in ansible_run_tags"
 ```

### Terraform (optional)

If you want to work on the terraform code itself outside of ansible, you want to setup the `terraform.tfvars`-file. You can deploy this file with the following `ansible-playbook` command:

```bash
ansible-playbook ansible/main.yml --tags=tfvars
```

Another options is to create a copy of the `terraform.tfvars.example` file, fill in the token variables with your API's key and setup the server maps manually.

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars 
```

Then `cd` to the terraform project folder and run terraform as usual.

```bash
terraform init
terraform apply
terraform destroy
```

**NOTE:** The ansible playbook creates, overwrites ***and*** deletes the `terraform.tfvars` file on each run. This is to ensure secrets such as API keys don't linger on disk whenever possible. Don't forget to use [ansible-vault](#ansible-vault-optional) if you care about this stuff 😉.

## License

MIT

## Authors

Justin Perdok ([@justin-p](https://github.com/justin-p/))

## Contributing

Feel free to open issues, contribute and submit your Pull Requests. You can also ping me on Twitter ([@JustinPerdok](https://twitter.com/JustinPerdok)).
