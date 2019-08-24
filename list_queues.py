import boto3

sqs = boto3.client('sqs', region_name='ap-south-1')

response = sqs.list_queues()

print(response)
