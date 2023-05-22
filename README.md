# cognito-authflow-study

This repository demonstrates how to implement [Developer authenticated identities authflow - Enhanced authflow](https://docs.aws.amazon.com/cognito/latest/developerguide/authentication-flow.html) using Amazon Cognito.

- [app](./app)
  - 'Developer Provider' (backend application implemented with Golang)
- [client](./client)
  - Frontend application running on 'Device' 
  - This application access a configuration hosted on [AWS AppConfig](https://docs.aws.amazon.com/appconfig/latest/userguide/what-is-appconfig.html) using credentials obtained through the authflow.
- [infra](./infra) 
  - Terraform scripts to build Amazon Cognito and AWS AppConfig resources 


