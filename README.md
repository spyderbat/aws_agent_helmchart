# aws_agent_helmchart
Public Spyderbat AWS Agent Helm Chart repository

Default settings that can be altered in the Values.yaml are:

|Parameter| 	Parameter from values.yaml	 | Default Value | Details                                                                                                                                                           |
|---------|--------------------------------|---------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| CPU resource request | resources:requests:cpu | 100m ||
| CPU resource limit | resources:limits:cpu | 1000m ||
| Memory resource request | resources:requests:cpu | 512Mi ||
| Memory resource limit | resources:limits:memory | 10240Mi ||
| aws agent configuration | awsAgentConfig: || The yaml configuration for the aws agent behaviorand connectivity. See below for detailed explanation
| aws access key id (optional)| credentials: aws_access_key_id || Explicit aws credentials to access the AWS api. Will be mapped to kubernetes secrets that will be mounted as volume in the aws agent container. Use a service account that assumes an AWS role if you don't want to configure your AWS credentials using kubernetes secrets (see serviceAccount setting below) |
| aws secret access key (optional)| credentials: aws_secret_access_key || Explicit aws credentials to access the AWS api. Will be mapped to kubernetes secrets that will be mounted as a secret volume in the aws agent container. Use a service account that assumes an AWS role if you don't want to configure your AWS credentials using kubernetes secrets (see serviceAccount setting below)|
| spyderbat_api_key (optional) | credentials: spyderbat_api_key || API key to connect to the spyderbat backend. Will be mapped to kubernetes secret that will be mounted as a secret volume in the aws agent container. If you are running your cluster in AWS, and want to avoid using kubernetes secrets, you can use AWS Secrets Manager instead. Leave this entry empty then, and enable secrets manager (see setting below) |
|service account create toggle| serviceAccount: create| true | When set to true, the helm chart will create a service account that can assume an AWS IAM role, which avoids the need for providing AWS credentials in kubernetes secrets, and controls what type of access is provided to the AWS agent to do its job|
|service account name| serviceAccount:name | aws-agent-serviceaccount | The name of the service account the aws agent will use. If you want to control the creation of this service account yourself, set the serviceAccount: create toggle to false, and create the service account yourself. Make sure it is created in the same namespace as the aws agent, and ensure the service account is associated with an appropriate AWS role|
|service account role annotation| serviceAccount: awsRoleAnnotation |eks.amazonaws.com/role-arn| The annotation string used to specify what IAM role the service account is to be associated with. For Amazon EKS clusters, this is eks.amazonaws.com/role-arn. Consult your kubernetes provider documentation for details how to associate with an IAM role if you are using another solution. |
|service account AWS role arn | serviceAccount: awsRoleArn ||The arn of the IAM role that the service account should assume. This role should have the permissions required to run the awss agent (see below for details)
|awsSecretsManager toggle | awsSecretsManager:enabled |false | When set to true, the AWS Agent will use a secret stored in AWS secrets manager to access the spyderbat api key. See below for details on use of AWS Secrets Manager|






## AWS Agent Configuration settings
The aws agent more detailed configuration is found under the awsAgenConfig section in the values.yaml, and will be mapped to a kubernetes config map after helm install, where it can be adjusted after installation if any adjustments are needed post-install. 

The configuration settings for the AWS Agents are:

### Agent to spyderbat transport settings

|Parameter | Default Value | Details |
|----------|---------------|---------|
| spyderbat_org | "your spyderbat org id here"| The spyderbat organization id the agent will send its data to. You must provide your spyderbat organization id for the agent to work|
| spyderbat_source | | The spyderbat source id that the aws agent got registered as. If not provided, a source_id based on the spyderbat_org will be used. *TODO* - _We need registration tooling upfront to support registering a source upfront of the helm chart_ |
| spyderbat_api_url| https://api.prod.spyderbat.com | This is the API endpoint for the spyderbat api. There should be no need to change this default for production deployments|
| send_buffer_size | 50 | This is a flow control setting for the data transport to the spyderbat backend. The aws agent will wait and accumulate to upt to the send_buffer_size of messages before it initiates a data transfer to the backend. This can be overruled by send_buffer_bytes_size and send_buffer_max_delay setting|
| send_buffer_bytes_size| 10000 | This is a flow control setting for the data transport to the spyderbat backend. The aws agent will wait and accumulate to upt to the send_buffer_size_bytes of total size of all messages in the send buffer before it initiates a data transfer to the backend. This can be overruled by send_buffer_size and send_buffer_max_delay setting|
| send_buffer_max_delay | 15 | This is a flow control setting for the data transport to the spyderbat backend. The aws agent will wait for a maximum of send_buffer_max_delay seconds before it will send its current send buffer of messages to the backend. This ensures in case of low incoming message volume that the data will not be retained in the send buffer for too long, even when the send_buffer's size limits in nr of message and nr of bytes have not been reached yet|
| log_level| INFO | The level of standard output logging the agent will log as. Possible values are DEBUG, INFO, WARNING, ERROR and CRITICAL|

### AWS Service polling settings
In the awsAgentConfig - pollers section of the configuration, you can configure what type of services you want to poll, from which regions in your AWS account(s), with which frequence and optionally using which roles to assume. 

For every type of service you want to poll, you'll create a service section, and can then specify settings and regions for the polling. 

The currently supported services to poll are:
#### guardduty

This poller will query the AWS GuardDuty API to collect all GuardDuty findings for a region, and send them to the spyderbat backend, where they will be analyzed and integrated in the causal context graph to support investigations of these findings

The applicable settings for a guardduty poller are:
    
|Parameter | Default Value | Details |
|----------|---------------|---------|
| polling_interval|30 |the interval in seconds the poller will use to poll the api for new data|
|intial_loopback| 86400 | Upon starting for the first time, the poller will query the guardduty api and ask for findings dating back the initial_loopback number of seconds ago. This will collect findings that were present before the agent started up. The default amount to looking back 24 hours initially.| 
| role_arn(optional) | | When specified, the poller will first assume this specific role before calling on the GuardDuty api. The role should have read permissions for the GuardDuty service in the accounts and regions you want to collect.  
|regions|  |You can specify a list of regions to poll for. For these individual regions is it possible to provide more specific settings for polling interval,  initial_loopback and role_arn, for that region specifcally|

Example guardduty polling configuration
```yaml
 pollers:
  - service: guardduty
    role_arn: arn:aws:iam::429857113775:role/GuardDutyReadOnly
    polling_interval: 30
    initial_lookback: 86400
    regions:
    - region: us-east-1
    - region: us-east-2
      role_arn: arn:aws:iam::623853115734:role/GuardDutyReadOnly
      polling_interval: 60

    - region: us-west-2
```
The example showcases you can specify general polling properties at the service level, but overrule these for a specific region, should you want to.

#### ec2tags

This poller will query the AWS EC2 API to describe instances in a region, and collect the AWS tags on these instances and send them to the spyderbat backend, where they will be used to enrich the machine models in the causal context graph.  

The applicable settings for the ec2tags poller are:
    
|Parameter | Default Value | Details |
|----------|---------------|---------|
| polling_interval|30 |the interval in seconds the poller will use to poll the api for new data|
| role_arn(optional) | | When specified, the poller will first assume this specific role before calling on the GuardDuty api. The role should have read permissions for the GuardDuty service in the accounts and regions you want to collect.  
|regions|  |You can specify a list of regions to poll for. For these individual regions is it possible to provide more specific settings for polling interval and role_arn, for that region specifcally|

Example ec2tags polling configuration
```yaml
  - service: ec2tags
    polling_interval: 5
    regions:
    - region: us-east-1
    - region: us-east-2
    - region: us-west-1
```
This shows a simple configuration where the settings are the same for all regions, and no arn_role is configured.

## Use of AWS Secrets Manager




