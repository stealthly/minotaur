## Building the AMI

* Install [Packer](http://packer.io).

* Ensure that your AWS credentials are accessible via a [credentials](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#cli-config-files) file or AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables.

* Run `packer build packer.json`. Once completed, update the CloudFormation [template](cfn.template)'s AMI map.