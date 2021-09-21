TASK 1:


## To apply terraform template for Production

```
terraform init
terraform plan -var-file='production.tfvars'
```
Note:
If you want to enable SSL for the application, please provide the certificate arn variable. Or if you leave it blank as default, your app is running with on port 80 only
File `~/.aws/credentials` points to credentials file located in your home directory. It has following format:
```
[default]
aws_access_key_id = <your access key>
aws_secret_access_key = <your secret key>
```
You should see a lot of output ending with this
```
Plan: 38 to add, 0 to change, 0 to destroy.
```
Run:
```
terraform apply -var-file='production.tfvars'
```
Output should see something similar to this...
```
Apply complete! Resources: 38 added, 0 changed, 0 destroyed.

Outputs:
...
```

## Same actions for Staging evironment except -var-file='stage.tfvars'

TASK 2:


## Run command
```
NAME="sample" && docker build -t $NAME . && alias samplecli='docker run -it $NAME'
```
Then get the cli output for example like:
```
samplecli users 1
samplecli accounts 2
```
