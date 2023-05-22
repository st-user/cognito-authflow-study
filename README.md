# cognito-authflow-study

This repository demonstrates how to implement [Developer authenticated identities authflow - Enhanced authflow](https://docs.aws.amazon.com/cognito/latest/developerguide/authentication-flow.html) using Amazon Cognito.

- [app](./app)
  - 'Developer Provider' (backend application implemented with Golang)
- [client](./client)
  - Frontend application running on 'Device' 
  - This application accesses a configuration hosted on [AWS AppConfig](https://docs.aws.amazon.com/appconfig/latest/userguide/what-is-appconfig.html) using credentials obtained through the authflow.
- [infra](./infra) 
  - Terraform scripts to build Amazon Cognito and AWS AppConfig resources 

**NOTE:**

The following steps are omitted in the application of this repository for simplicity.

- `1. Login via Developer Provider (code outside of Amazon Cognito)`
- `2. Validate the user login (code outside of Amazon Cognito)`

The application starts the flow from `3. GetOpenIdTokenForDeveloperIdentity`.


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

Terraform should output identity pool ID. We use this when starting 'app'.

**NOTE:**

We have to deploy the configuration hosted on AWS AppConfig.
Please see [Step 5: Deploying a configuration](https://docs.aws.amazon.com/appconfig/latest/userguide/appconfig-deploying.html) for detailed information.



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

You should see a webpage on `localhost:3000` and a `start` button on it.
You can test the authflow by pushing the button!

# References

- [Developer authenticated identities authflow - Enhanced authflow](https://docs.aws.amazon.com/cognito/latest/developerguide/authentication-flow.html)
- [AWS SDK for JavaScript v3](https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/index.html)
- [Using Developer Authenticated Identities with Cognito Identity Pools In TypeScript](https://spin.atomicobject.com/2020/02/26/authenticated-identities-cognito-identity-pools/)
- [Exploring Feature Flag use AWS AppConfig](https://dev.to/aws-builders/exploring-feature-flag-use-aws-appconfig-9f9)
