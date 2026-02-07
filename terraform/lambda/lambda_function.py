import json
import boto3
import os

def lambda_handler(event, context):
    dynamodb = boto3.resource('dynamodb')
    table_name = os.environ.get('TABLE_NAME')
    allowed_origin = os.environ.get('ALLOWED_ORIGIN')
    
    table = dynamodb.Table(table_name)

    response = table.get_item(Key={"id": "visitor_count"})
    item = response.get("Item", {})
    view_count = int(item.get("count", 0))

    view_count += 1

    table.put_item(Item={"id": "visitor_count", "count": view_count})

    return {
        "statusCode": 200,
        "body": json.dumps({"count": view_count}),
        "headers": {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': allowed_origin
        }
    }