{{- define "awsAgentName" -}}
{{- printf "aws-agent-%d" (.Values.awsAgentConfig.aws_account_id | int ) -}}
{{- end -}}