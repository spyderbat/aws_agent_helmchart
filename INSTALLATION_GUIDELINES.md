# Installation guidelines for the aws agent helm chart
## Getting the spyderbat aws-agent helmchart

To add the aws agent helmchart to your helm repo, run the following:
```bash
helm repo add awsagent https://spyderbat.github.io/aws_agent_helmchart/
helm repo update
```
## Preparing the configuration

For a successful installation, you will need to do some upfront preparation and make some choices on how you want to manage the spyderbat credentials and aws credentials the aws agent needs to do its work.

### Deciding on the AWS credentials approach
You have two basic choices here

#### 1. Use explicitly provided AWS credentials managed in kubernetes secret
The simplest approach is to provide the aws access key and secret key as parameters to the helm chart install.
The helm chart will then put these in a kubernetes secret that will be deployed. The aws agent container will access these secrets from a mounted secret volume.

This is configured in the helm chart with the properties:
```yaml
    credentials:
        # Optionally you can specify the aws credentials to use for the agent explicitly here
        # (if you are not using a service account that assumes an IAM role to pull data)
        # we recommend setting these with the --set option during helm install
        aws_access_key_id:
        aws_secret_access_key:
```

You then have the option to use these credentials directly in the actual polling of data, or to use a specific AWS IAM role to assume by the poller when it actually polls the data.
To assume a specific AWS IAM role for the guardduty collection, configure the role_arn in the poller setting
```yaml
pollers:
  - service: guardduty
    role_arn: your arn here
```
If you don't specify a role_arn, the poller will use the provided credentials for the actual polling.

You will need to ensure the credentials and/or the roles used have the appropriate permissions to collect guardduty information in the AWS Accounts and regions you're interested in.

In case you only use aws credentials, and no assumed role, ensure the IAM identity associated with the credentials have GuardDuty read-only permissions. Amazon provides an AWS Managed IAM Policy caled _AmazonGuardDutyReadOnlyAccess_ you can leverage for this.

In case you use credentials combined with a configured role to assume you must ensure
- that the assumed role has GuardDuty read-only permissions. Amazon provides an AWS Managed IAM Policy caled _AmazonGuardDutyReadOnlyAccess_ you can leverage for this.
- that the assumed role has a trust policy that ensures the credentials you have provided can assume that role

#### 2. Use a kubernetes service account that is associated with an AWS IAM role

If you are uncomfortable with explicitly providing AWS credentials to the AWS agent, if your kubernetes solution or managed service supports it, you can use that capability instead.

In this case, the helm chart will create an aws-agent-serviceaccount, that can assume an AWS IAM role.
In this scenario, the aws agent will not require the aws credentials to be passed to it.

How the kubernetes solution you are using does this will be dependent vendor by vendor, we provider below how it can be done with Amazon's AWS EKS Service

First, you must ensure that the IAM roles EKS will be using are created appropriately so that the EKS cluster can assume these roles. AWS documents this process here:
 - https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html (overview and prerequisites)
 - https://docs.aws.amazon.com/eks/latest/userguide/associate-service-account-role.html (how to create a service account with a matching IAM Role)

    In the instructions in the second link, when you go through these process, adjust appropriately to ensure the IAM policy used has GuardDuty read permission, specifically, replace the example policy in the document with a policy allowing for GuardDuty read only access (see the AWS Managed policy _AmazonGuardDutReadOnlyAccess_ as a
    starting point)

    We recommend that you adjust the provide eksctl command as follows (adjust the policy arn to your own arn):
    ```bash
    eksctl create iamserviceaccount --name aws-agent-serviceaccount --namespace spyderbat --cluster my-cluster --role-name SpyderbatAWSAgentRole \
    --attach-policy-arn arn:aws:iam::111122223333:policy/my-policy --approve
    ```
Now that the service account and the associate IAM role is created, you can use it in the helm chart.

To configure for this scenario, the following settings in the values.yaml need to be set
```yaml
serviceAccount:
  # Set enabled to true if you want to create a service account for the agent and have it assume
  # an AWS role for interacting with AWS (recommended)
  enabled: true

  # Set create to true if you want the helm chart to create the service account for you
  create: true

  # The name of the service account to use (or create)
  name: aws-agent-serviceaccount
  # Use the below annotation for EKS based clusters to associate the service account with an IAM role
  awsRoleAnnotation: eks.amazonaws.com/role-arn
  # Provide the ARN to the role with the appropriate trust policy and
  # permissions to interact with AWS services
  awsRoleArn: arn of the IAM role that the service account should assume
```

The eksctl command will have created a service account already, and you could set the 'create' flag to false, however, we recommend for it to be set anyway, as this will assure we can recreate the serviceAccount if need be.
If you choose to follow that guidance, you'll want to delete first the kubernetes service account that was created by the eksctl command, so that the helm chart can recreate it.
```bash
kubectl delete serviceaccount aws-agent-serviceaccount -n spyderbat
```
Now add the role arn of the IAM role that was created by the eksctl command in the awsRoleArn setting of the values.yaml

If you are using another kubernetes solution that support assuming AWS IAM Roles, your steps will be different but similar. Use your kubernetes providers specific annotation string in the awsRoleAnnotation setting for establishing the link between the service account and the IAM role


### Deciding on the spyderbat credentials approach
The spyderbat credential you need to access our backend is the spyderbat api key.
To find out how to get a spyderbat api key please see <here(need link to spyderbat doc on how to make an api key)>
We provide 2 options to manage this credential.

#### 1. Use explicitly provided spyderbat api key, managed in kubernetes secret
The simplest approach is to provide the spyderbat api key as a parameter to the helm chart install.
The helm chart will then put this in a kubernetes secret that will be deployed. The aws agent container will access this from a mounted secret volume.

This is configured in the helm chart with the properties:
```yaml
credentials:
  # The spyderbat api key to use for the agent.
  # This does not need to be set if you store it in AWS secrets manager (see next section)
  # we recommend setting this with the --set option during helm install
  spyderbat_api_key:
```

#### 2. Use AWS Secrets Manager to store the spyderbat api key
If you prefer to manager your secrets more centrally we offer an integration with AWS Secrets Manager and EKS.
This option requires the use of a kubernetes service
To use this option, first take the following preparation steps
Add the spyderbat api key as a secret in secrets manager, either via the secrets manager UI, or using the following commands
```bash
aws secretsmanager create-secret --name \<name\> --region \<region\>
- aws secretsmanager put-secret-value --secret-id \<name\> --region \<region\> --secret-string "{\"spyderbat_api_key\":\"\<key\>\"}"
aws secretsmanager get-secret-value --secret-id \<name\> --region \<region\>
```

helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts

helm install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver --namespace kube-system --set syncSecret.enabled=true

kubectl apply -f https://raw.githubusercontent.com/aws/secrets-store-csi-driver-provider-aws/main/deployment/aws-provider-installer.yaml

## Running the helm chart install
You can now run the install, by running:
```bash
helm install awsagent awsagent/awsagent --values my_values.yaml --set xxxx
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


