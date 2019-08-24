import logging
import boto3
from botocore.exceptions import ClientError


def terminate_instances(instance_ids):
    """Terminate one or more Amazon EC2 instances

    :param instance_ids: List of string IDs of EC2 instances to terminate
    :return: List of state information for each instance specified in instance_ids.
            If error, return None.
    """


    # Terminate each instance in the argument list
    ec2 = boto3.client('ec2', region_name='ap-south-1')
    try:
        states = ec2.terminate_instances(InstanceIds=instance_ids)
    except ClientError as e:
        logging.error(e)
        return None
    return states['TerminatingInstances']


def main():
    """Exercise terminate_instances()"""

    # Assign these values before running the program
    ec2_instance_ids = ['i-0c50fd9ede330794f']

    # Set up logging
    logging.basicConfig(level=logging.DEBUG,
                        format='%(levelname)s: %(asctime)s: %(message)s')

    # Terminate the EC2 instance(s)
    states = terminate_instances(ec2_instance_ids)
    if states is not None:
        logging.debug('Terminating the following EC2 instances')
        for state in states:
            logging.debug(f'ID: {state["InstanceId"]}')
            logging.debug(f'  Current state: Code {state["CurrentState"]["Code"]}, '
                          f'{state["CurrentState"]["Name"]}')
            logging.debug(f'  Previous state: Code {state["PreviousState"]["Code"]}, '
                          f'{state["PreviousState"]["Name"]}')


if __name__ == '__main__':
    main()
