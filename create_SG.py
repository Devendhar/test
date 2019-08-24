import boto3

client = boto3.client('ec2', region_name='ap-south-1')

ec2 = boto3.resource('ec2', region_name='ap-south-1')

filter = [{'Name': 'tag:Name', 'Values': ['Default']}]
vpcs = ec2.vpcs.filter(Filters=filter)

for vpc in vpcs:
    vpcId = vpc.id


security_group = ec2.create_security_group(Description='Custom Security Group', GroupName='SG1', VpcId=vpcId)

print(security_group.id)
