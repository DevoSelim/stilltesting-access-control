def handler(event, context):
    principal_id = "temp-user"

    policy_document = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Action": "execute-api:Invoke",
                "Effect": "Allow",
                "Resource": event["methodArn"],
            }
        ],
    }

    return {
        "principalId": principal_id,
        "policyDocument": policy_document,
        "context": {
            "token_valid": "true"
        }
    }
