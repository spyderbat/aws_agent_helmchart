# Installation guidelines for the aws agent helm chart
## Getting the spyderbat aws-agent helmchart

To add the aws agent helmchart to your helm repo, run the following:
```bash
helm repo add awsagent https://spyderbat.github.io/aws_agent_helmchart/
helm repo update
```


## Preparing the configuration
## Running the helm chart install
You can now run the install, by running:
```bash
helm install awsagent awsagent/
```
## Troubleshooting 
For detailed configurable settings you can control for the aws agent helm chart, please refer to the [README.md](README.md)

An important factor to consider for your configuration is how to configure credentials and permission to the AWS resources being polled by the AWS agent. 
There are multiple individual settings that help you control these, depending on where you want to maintain these credentials, and how tightly your kubernetes provider is integrated with AWS. 

We provide here guidance for 3 levels of security and aws integration for credential management.

### 1. AWS credentials and spyderbat credentials explicitly provided and managed in kubernetes secrets

- Explanation
- Sample config

### 2. Use of a kubernetes service account that assumes an IAM role to access the AWS resources, and spyderbat credentials explicitly provided and managed in kubernetes secrets
- Explanation
- Sample config

### 3. Use of kubernetes service account that assumes an IAM role, and use of AWS Secretsmanager for spyderbat credentials management.
- Explanation
- Sample config

