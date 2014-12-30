infrastructure/aws/bastion
==================

Scripts/recipes/configs to spin up and manage Bastion instance for environment.

If Amazon EC2 instances are located inside the private subnet, you will not be able to connect to them directly. To connect to these instances, a bastion host must reside in a public subnet. Bastion is pretty much nothing but SSH gateway with centralized user management (in our case, accounts info is stored on github).

To be able to log in on the instance you'll need:

- SSH key for the environment (provided by Amazon)
- Separate JSON file with your credentials in bastion/chef/data_bags/users folder

This file has the following format:
```
{
  "id"        : "username that will be used for SSH login",
  "comment"   : "name and surname of a person",
  "ssh_keys"  : ["personal SSH key (public part of it, including key type"],
  "environments": [ list of environment person is granted access to ]
}
```

####Example:

smotovilovets.json
```
{
  "id"        : "smotovilovets",
  "comment"   : "Sergey Motovilovets",
  "ssh_keys"  : ["ssh-rsa SSH_KEY_GOES_HERE"],
  "environments": ["vagrant","bdoss-dev"]
}
```

NOTICE: If you no longer want user to be able to access the environment - DO NOT DELETE THE JSON FILE, remove the environment from person's "environments" list instead.

Bastion is pulling these files every 5 minutes, so be patient and let Bastion configure itself before trying to log in.

Next step is to use template_ssh script to template your ssh config file. Whole config file will be created and populated with your user name and bastion ip for each environment deployed. Reuse this script every time you create a new 

```
templatessh
```

Now you can log in to the instances in, for example, bdoss-dev environment simply by typing:
```
ssh ip-10-0-X-X.bdoss-dev.aws
```