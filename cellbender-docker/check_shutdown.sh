#!/bin/bash --login
path=$1
TOKEN=`curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
while sleep 5; do
	    HTTP_CODE=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s -w %{http_code} -o /dev/null http://169.254.169.254/latest/meta-data/spot/instance-action)
		if [[ "$HTTP_CODE" -eq 401 ]] ; then
			echo 'Refreshing Authentication Token'
			TOKEN=`curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
		elif [[ "$HTTP_CODE" -eq 200 ]] && [ -f ckpt.tar.gz ]; then
			aws s3 cp  ckpt.tar.gz "${path}ckpt.tar.gz"
		fi
done
