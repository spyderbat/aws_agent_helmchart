# aws_agent_helmchart
Public Spyderbat AWS Agent Helm Chart repository

Default settings that can be altered in the Values.yaml are:

|Parameter| 	Parameter from values.yaml	 | Default State	 | Default Value (if enabled) | Details                                                                                                                                                           |
|---------|--------------------------------|-----------------|----------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| CPU resource request | resources:requests:cpu | N/A | 100m ||
| CPU resource limit | resources:limits:cpu | N/A | 1000m ||
| Memory resource request | resources:requests:cpu | N/A | 512Mi ||
| Memory resource limit | resources:limits:memory | N/A | 10240Mi ||
| aws agent configuration | awsAgentConfig: | N/A | | The yaml configuration for the aws agent behaviorand connectivity. See below for detailed explanation
| aws access key id (optional)| credentials: aws_access_key_id | N/A || Explicit aws credentials to access the AWS api. Will be mapped to kubernetes secrets that will be mounted as volume in the aws agent container. Use a service account that assumes an AWS role if you don't want to configure your AWS credentials using kubernetes secrets (see serviceAccount setting below) |
| aws secret access key (optional)| credentials: aws_secret_access_key | N/A || Explicit aws credentials to access the AWS api. Will be mapped to kubernetes secrets that will be mounted as a secret volume in the aws agent container. Use a service account that assumes an AWS role if you don't want to configure your AWS credentials using kubernetes secrets (see serviceAccount setting below)|
| spyderbat_api_key (optional) | credentials: spyderbat_api_key | N/A || API key to connect to the spyderbat backend. Will be mapped to kubernetes secret that will be mounted as a secret volume in the aws agent container. If you are running your cluster in AWS, and want to avoid using kubernetes secrets, you can use AWS Secrets Manager instead. Leave this entry empty then, and enable secrets manager (see setting below) |
|service account create toggle| serviceAccount: create| N/A| true | When set to true, the helm chart will create a service account that can assume an AWS IAM role, which avoids the need for providing AWS credentials in kubernetes secrets, and controls what type of access is provided to the AWS agent to do its job|
|service account name| serviceAccount:name | N/A | aws-agent-serviceaccount | The name of the service account the aws agent will use. If you want to control the creation of this service account yourself, set the serviceAccount: create toggle to false, and create the service account yourself. Make sure it is created in the same namespace as the aws agent, and ensure the service account is associated with an appropriate AWS role|
|service account role annotation| serviceAccount: awsRoleAnnotation ||eks.amazonaws.com/role-arn The annotation string used to specify what IAM role the service account is to be associated with. For Amazon EKS clusters, this is eks.amazonaws.com/role-arn. Consult your kubernetes provider documentation for details how to associate with an IAM role if you are using another solution. |
|service account AWS role arn | serviceAccount: awsRoleArn | N/A||The arn of the IAM role that the service account should assume. This role should have the permissions required to run the awss agent (see below for details)



## AWS Agent Configuration settings
| spyderbat organization | awsAgentConfig:spyderbat_org | N/A | "your spyderbat org id here"| You must provide your spyderbat organization id for the agent to work|
| spyderbat api url | awsAgentConfig:spyderbat_api_url| N/A | https://api.prod.spyderbat.com | There should be no need to change this default for production deployments|

## Required permissions for Assumed AWS Role


