# gerrard-learns-terraform
A repository for me to learn Terraform and AWS. As of writing this document
assumes Terraform version `v0.12.8` and using Terraform from MacOS.

This is not intended to be a copy of Terraform documentation but rather my
interpretation of that documentation and its use with AWS. A lot of behind the
scenes work is done when using AWS and I want to help clarify and correlate it
to it's use in AWS.

This document will also point you to the relevant Terraform and AWS documentation
where applicable.

Please feel free to raise a github issue should you like to see anything improved
or clarified.

## Index
* [Speaking to Amazon](#speaking-to-amazon)
  + [Credentials](#credentials)
  + [Real engineers still use the keyboard(Most of the times)](#real-engineers-still-use-the-keyboard-most-of-the-times-)
* [01 Hello World](#01-hello-world)
* [02 Hello World, Take 2](#02-hello-world--take-2)
* [03 Hello World, Take 3](#03-hello-world--take-3)
* [04 Variables & Names](#04-variables---names)
  + [Names](#names)
  + [Variables](#variables)
* [05 terraform init](#05-terraform-init)

## Speaking to Amazon
### Credentials
You will need to login to the [AWS console](https://console.aws.amazon.com/) to
create an access key if you don't already have one. For now it will be insecure
in as much as the key generated will have *root* access to your AWS account. I
will circle back to this later on.

Creating a new access key could not be simpler, browse to IAM, under Access keys
click on *Create New Access Key* and copy the *Access Key ID* and
*Secret Access Key*.

Create a new file `~/.aws/credentials`.
Make the permissisions `-600` to keep it secure even if you are the only person
using the machine.
The file should look as follows:
```
[default]
aws_access_key_id = AKIAJDOR3DRQ6WSB4E5Q
aws_secret_access_key = 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
```
The above credentials is not valid, incase you wanted to try it.

### Real engineers still use the keyboard(Most of the times)
Install [aws cli](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html),
as this will come in handy to prevent having to use the web GUI all the time.

Assuming you have never created an AWS EC2 instance before the following command
`aws ec2 describe-instances` will give this output:
```
{
    "Reservations": []
}
```
If instead you get the error message `You must specify a region. You can also configure your region by running "aws configure".` then do that and once done have a look at `~/.aws/config`

If you have created(using the webGUI) your machine but you still get `[]` back then most likely
you created your machine in a different availability zone to what is set in the
*config* file.
You can use `aws ec2 describe-instances --debug` to find problems. This is how
I realised why I was not seeing any results.

## 01 Hello World
Terraform is going to look for a `.tf` file within the directory that you are
running terraform. So to get started we will create a `tf` file and call it
anything you want as long as it ends with *.tf*

The contents should be similar to following:
```
provider "aws" {
  profile    = "default"
  region     = "eu-west-2"
}

resource "aws_instance" "helloworld01" {
  ami           = "ami-00a1270ce1e007c27"
  instance_type = "t2.micro"
}
```

Once this file is created we can run `terraform init`. This will download the
lastest plugins that is referenced in your *tf* file. In this case it would be
the aws provider. If you are unlucky enough to be behind a proxy then you need
to set bash variables `HTTPS_PROXY` and `HTTP_PROXY` for good measure. The last
time I checked this terraform were looking for the uppercase variables so if you
have `https_proxy` set then it won't work.

Next step is to run `terraform plan` which will tell you what terraform intends
to do but no actually execute. If you are happy with what terraform wants to do
then you can run `terraform apply`. Be warned though that this will prompt you
for confirmation. To avoid this hand-holding just add the `-auto-approve` flag
because you know what you are doing.

Note that if you run `terraform plan` again after a succesfull execution of `terraform apply`
it will tell you *No changes. Infrastructure is up-to-date.*

Terraform will also have created a `terraform.tfstate` file where it stores the
*state* of the resources it just created. This allows terraform to consolidate
your current infrastruture in AWS with what you want to manage via terraform. If
you thus delete the tfstate file and don't delete the actual resources in AWS,
you will end up with in the case of this example two new servers.

To verify that something actually happened, you can use the WebGUI and you will
see the machine created there or alternatively you can run `aws ec2 describe-instances`
which will give you a list of instances in your default region.

* Q. How/Where do I get a list of AWS regions?
  A. It would depend on the service you are using and if that service is implemented in a specific region. For example to get a list of regions that supports EC2 you would use `aws ec2  describe-regions --all-regions` or simply `aws ec2  describe-regions` which would give you a list of regions where your account can create ec2 instances. This [AWS Documentation](https://docs.aws.amazon.com/general/latest/gr/rande.html#ec2_region) also provides a definitive list of regions for all *AWS Service Endpoints*
* Q. Where do I get the ami value from to put in my *tf* file?
  A.
* Q. I gave the server a name but in the GUI it is still just a number?
  A. The name given is the name for the server within your terraform code, but
     meand exactly nothing to AWS, you are after all just a number.
* Q. How do I connect to this server I just build?
  A. See take 2.

## 02 Hello World, Take 2
I have successfully created my new machine but how do I connect to it? So perhaps
you have created a few machines already using the GUI and for previous machines
you created a key and you selected the key when you created your last machine. Ok
easy lets just specify the key.
```
resource "aws_instance" "helloworld01" {
  ami           = "ami-00a1270ce1e007c27"
  instance_type = "t2.micro"
  key_name      = "testingkey45"
}
```
Great, it creates the machine and even displays the keyname you specified but
when you ssh to it......... nothing happens. The reason is simple, when you
compare it against your EC2 instance created with the WebGUI you will notice it
is part of a default security group. So you can't ssh to your newly created
machine because it is blocked by default firewalls.
Lets fix that by adding it to the default security group.
```
resource "aws_instance" "helloworld01" {
  ami             = "ami-00a1270ce1e007c27"
  instance_type   = "t2.micro"
  key_name        = "testingkey45"
  security_groups = ["launch-wizard-5"]
}
```
Now, I am by no means advocating that this is a good idea but it is simple and
it will get things working. We should really create better security groups and
it will follow.

Q. What happens if I create the machine with terraform and then modify properties
   like the security group? Does it update the machine or does it recreate it from scratch?


## 03 Hello World, Take 3
We might not want to use a generic or predefined key so, *take 3* goes through
how you would make use of your own pre-defined sshkey pair.

We add the following snippet to our *tf* file.
```
resource "aws_key_pair" "glt-keypair" {
  public_key = "${file(pathexpand("~/.ssh/glt_rsa.pub"))}"
}
```
There is 3 things to note in the above example:
1. `"${}"` syntax is terraform's interpolation syntax. See [docs](https://www.terraform.io/docs/configuration-0-11/interpolation.html).
1. `pathexpand()` is a function that fully expands the path so it can be read everywhere. See [docs](https://www.terraform.io/docs/configuration/functions/pathexpand.html).
1. `file` is a [function] that will return the contents of the file rather than a link to the file. See [docs](https://www.terraform.io/docs/configuration/functions/file.html).

To connect to this machine:
```
ssh -l ec2-user -i ~/.ssh/glt_rsa  <your ip>
```

The ip can either be obtained from the *terraform.tfstate* file or from the WebUI


Q. Does the ordering of terraform resources matter?
A. No, in this example we defined the key resource after we referenced it in the
   *aws_instance* resource.

## 04 Variables & Names
### Names
The first thing we do is to add a name for the key we created in the previous
example. You might have noticed the keyname having a terraform generated name
like `terraform-20190907083954296400000001` which is not very intelligible.
The resource will now look like this:
```
resource "aws_key_pair" "glt-keypair" {
  key_name   = "glt-keypair"
  public_key = "${file(pathexpand("~/.ssh/glt_rsa.pub"))}"
}
```
Where the keyname is whatever you want to call it.

### Variables
If you remember back you can have multiple *tf* files. We will be putting our
variables in a separate file called `variables.tf`. The name is not important so
you could call it `abc.tf` as long as it ends with *.tf* and the name makes
sense to you.

Terraform's variable documentation can be found [here](https://www.terraform.io/docs/configuration/variables.html).

Variables are declared in a *variable block*
```
variable "region" {
  default = "eu-west-2"
}
```
and can be referenced by using
* `var.region`
* or `"${var.region}"`

## 05 terraform init
