import json
import os
import boto3

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["ACCESS_EVENTS_TABLE"])

def handler(event, context):
    for record in event.get("Records", []):
        try:
            body = json.loads(record["body"])
        except Exception:
            body = {"raw_body": record.get("body")}

        item = {
            "pk": body.get("pk", "EVENT#unknown"),
            "sk": body.get("sk", "TS#unknown"),
            "payload": json.dumps(body),
        }
        table.put_item(Item=item)

    return {
        "statusCode": 200,
        "body": "processed {} records".format(len(event.get("Records", []))),
    }
