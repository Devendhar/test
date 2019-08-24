import boto3

from botocore.exceptions import ClientError

ec2 = boto3.client('ec2', region_name='ap-south-1')

try:
    ec2.terminate_instances(InstanceIds=['i-0f4cda1c4bebb2a2e'], DryRun=False)
except ClientError as e:
    if 'DryRunOperation' not in str(e):
        print("You don't have permission to reboot instances.")
        raise
