# cognito-authflow-study

This repository demonstrates how to implement [Developer authenticated identities authflow - Enhanced authflow](https://docs.aws.amazon.com/cognito/latest/developerguide/authentication-flow.html) using Amazon Cognito.

- [app](./app)
  - 'Developer Provider' (backend application implemented with Golang)
- [client](./client)
  - Frontend application running on 'Device' 
  - This application access a configuration hosted on [AWS AppConfig](https://docs.aws.amazon.com/appconfig/latest/userguide/what-is-appconfig.html) using credentials obtained through the authflow.
- [infra](./infra) 
  - Terraform scripts to build Amazon Cognito and AWS AppConfig resources 

## How to run

#### Prerequisites

You have to install the followings beforehand.

- [Terraform](https://developer.hashicorp.com/terraform/downloads)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
  - Please make sure that credential information is properly configured.
- [Golang](https://go.dev/doc/install)
- [nodejs](https://nodejs.org/en)

#### infra

```bash
cd infra
cp secret.tfvars_sample secret.tfvars
```

Please edit the `secret.tfvars` like the following:

```
aws_account_id = "<Input your aws account id>" 
cognito_provider_name = "login.myapp.example.com"
```


```bash
terraform init
terraform plan -var-file="secret.tfvars"
terraform apply -var-file="secret.tfvars"

```

Terraform should output identity pool ID. we use this when starting 'app'.

#### app

```bash
cd app

export AWS_IDENTITY_POOL_ID= .... # your identity pool ID Terraform outputs
export AWS_LOGIN_PROVIDER=login.myapp.example.com # == 'cognito_provider_name' in secret.tfvars
export AWS_LOGIN_NAME=test_user
export AWS_TOKEN_DURATION_SECONDS=600
```

```bash
go run .
```

#### client

```bash
cd client

yarn start
```

You should see a webpage on `localhost:3000` and an `start` button on it.
You can test the authflow by pushing the button!

