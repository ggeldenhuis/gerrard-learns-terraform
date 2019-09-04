# gerrard-learns-terraform
A repository for me to learn Terraform and AWS. As of writing this document
assumes Terraform version `v0.12.8` and using Terraform from MacOS.

This is not intended to be a copy of Terraform documentation but rather my
interpretation of that documentation and its use with AWS. A lot of behind the
scenes work is done when using AWS and I want to help clarify and correlate it
to it's use in AWS.

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

## Hello World
