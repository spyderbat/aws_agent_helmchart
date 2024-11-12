update:
	git checkout master
	rm -rf /tmp/aws_agent_helmchart
	helm package ./ -d /tmp/aws_agent_helmchart
	git checkout published
	cp /tmp/aws_agent_helmchart/*.tgz ./
	git add *.tgz
	helm repo index ./
	git add index.yaml
publish:
	git checkout published
	git commit -a
	git push origin published
	git checkout master
