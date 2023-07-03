# wg-kit

A bundle of pre-defined Wireguard settings, a Python utility script for adding new client peers, and a Terraform script for creating a requisite VPC setup in AWS along for the Wireguard server. This allows for a public EC2 instances to be gated behind the Wireguard server.

I found that I was frequently deploying this setup, so I codified it with Terraform.

## Requirements

- AWS account
- An already-created key in EC2 named `wg-kit_key.pem`
- Terraform installed on your local dev environment

## AWS Credentials & Config

Place the following files and information in `./.secret`:

`.secret/credentials`
```ini
[default]
aws_access_key_id=<YOUR ACCESS KEY HERE>
aws_secret_access_key=<YOUR SECRET ACCESS KEY HERE>
```

`.secret/config`
```ini
[default]
region=<YOUR PREFERRED REGION CODE HERE>
```

An example region could be `us-west-2`.

You will also place your `wg-kit_key.pem` in the `.secret` folder. Be sure that it has the appropriate permissions for a private SSH key:

```sh
$ chmod 700 .secret/wg-kit_key.pem
```

## Run

```sh
$ chmod +x ./deploy.sh
$ ./deploy.sh
```

## Destroy AWS Resources

```sh
$ terraform destroy
```
