# Terraform 101

- This repo will explore terraform - a Hashicorp orchestration tool used as a part of Infrastructure as Code.

- IAC:
	- Configuration Management Tools
		- Chef, Puppet, Ansible...
		- For creating immutable infrastructure with playbooks etc...
		- If we install a package in one machine, this machine will have mutated, and change will need to be done in all others
		- End goal = AMI
	
	- Orchestration Tools
		- Terraform, Cloudform...
		- Will create infrastructure, the networking, security, monitoring and set-up around the machine that creates a production environment.
		- Eg:
			1) Automation server triggered
			2) Tests are run in machine created from AMI
			3) Test pass triggers next step on automation server
			4) New AMI created: previous AMI + changes
			5) Successful creation triggers next step in automation server
			6) Calls terraform script to create infrastructure and deploy

- The conjunction of the two allows us to define, maintain and manipulate our infrastructure as code, along with version control (git), and cloud providers (aws)

###### Terraform steps:
- Terraform creates VPC
- Creates subnets
- Adds rules and security
- Deploys AMIs and runs scripts

- Terraform will work with a cloud provider
- You will need programatic access and API keys
- Set these in environment variables (Start > Control Panel), using correct naming convention
	- Can also be set within main.tf file itself (DO NOT UPLOAD TO GITHUB WITH THIS METHOD)

### Terminology

- Providers
- Resources
	- ec2
- Variables

### Commands

- `terraform init`
- `terraform plan`
- `terraform apply`
- `terraform destroy`


### Set up

- Terraform download a prerequisite

1) Set up repo - .gitignore, scripts/, app/, db/, main.tf
2) `terraform init`
3) Write main.tf to create VPC and public components
	- See example file in this repo, and documentation
	- https://www.terraform.io/docs/index.html
	- Include prebuilt AMIs where possible
		- App instance
3) Use `terraform plan` and `terraform apply` to validate and create
4) Reference init.sh.tpl in data section of main.tf
	- This is a bash script that will run for the app instance
5) Export db_host, seed the database, install npm, start pm2
6) Go to public IP of instance to ensure app / AMI is working
7) Go back to main.tf, and create private (db) components
8) Use AMI or if starting from scratch:
	- Reference to an init.sh.tpl
	- Use provision.sh script here
9) Use `terraform apply` to check and confirm
10) Go to public IP of web instance (changes each apply) and check for /posts