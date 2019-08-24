import boto3
import pprint

client = boto3.client('ec2', region_name='ap-south-1')

sg_groups = []

sg_filter = [
        {
            'Name': 'tag:Env',
            'Values': ['prod', 'default']
        }
        ]

securityGroups = client.describe_security_groups(Filters=sg_filter)

for sg_group in securityGroups['SecurityGroups']:
    sg_groups.append(sg_group['GroupId'])

print(sg_groups)

filter = [
        {
            'Name': 'tag:Env',
            'Values': [
                'prod'
            ]
        }
        ]
response = client.describe_instances(Filters=filter)

networkInterfaceIds = []

for instances in response['Reservations']:
    for instance in instances['Instances']:
        for interfaceid in instance['NetworkInterfaces']:
          networkInterfaceIds.append(interfaceid['NetworkInterfaceId'])

print(networkInterfaceIds)

for interface in networkInterfaceIds:
    client.modify_network_interface_attribute(NetworkInterfaceId=interface, Groups=sg_groups)

