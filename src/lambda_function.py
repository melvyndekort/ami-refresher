import os
import logging
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ec2 = boto3.client('ec2')
ssm = boto3.client('ssm')
sns = boto3.client('sns')


def lambda_handler(event, context):
  logger.info('Original event: {}'.format(event))

  ami_id = get_ami_id(os.environ['AMI_PARAM_PATH_X86'])
  update_launch_template(os.environ['TEMPLATE_ARN_X86'], ami_id)

  ami_id = get_ami_id(os.environ['AMI_PARAM_PATH_ARM64'])
  update_launch_template(os.environ['TEMPLATE_ARN_ARM'], ami_id)

  terminate_instances()


def get_ami_id(param_name):
  response = ssm.get_parameter(
    Name=param_name
  )

  value = response['Parameter']['Value']
  logger.info('Retrieved AMI_ID from parameter store: {}'.format(value))
  return value


def get_current_launch_template_version(template_id):
  response = ec2.describe_launch_templates(
    LaunchTemplateIds=[template_id]
  )
  return str(response['LaunchTemplates'][0]['LatestVersionNumber'])


def create_launch_template_version(template_id, ami_id):
  response = ec2.create_launch_template_version(
    LaunchTemplateId = template_id,
    SourceVersion = "$Latest",
    VersionDescription="Latest-AMI",
    LaunchTemplateData={
      'ImageId': ami_id
    }
  )
  logger.info('Launch template version {} created'.format(response['LaunchTemplateVersion']['VersionNumber']))


def delete_previous_launch_template_version(template_id, previous_version):
  ec2.delete_launch_template_versions(
    LaunchTemplateId=template_id,
    Versions=[previous_version]
  )
  logger.info('Launch template version {} deleted'.format(previous_version))


def update_launch_template(template_id, ami_id):
  previous_version = get_current_launch_template_version(template_id)

  create_launch_template_version(template_id, ami_id)

  ec2.modify_launch_template(
    LaunchTemplateId = template_id,
    DefaultVersion = "$Latest"
  )
  logger.info('Launch template {} modified'.format(template_id))

  delete_previous_launch_template_version(template_id, previous_version)


def get_instances():
  response = ec2.describe_instances(
    Filters=[
      {
        'Name': 'tag:Name',
        'Values': ['lmgateway']
      }, {
        'Name': 'instance-state-name',
        'Values': ['running']
      }
    ]
  )

  instance_list = []

  for reservation in response['Reservations']:
    for instance in reservation['Instances']:
      instance_list.append(instance['InstanceId'])

  return instance_list


def terminate_instances():
  instance_list = get_instances()
  logger.info('Terminating instances: {}'.format(instance_list))

  ec2.terminate_instances(
    InstanceIds=instance_list
  )

def send_sns_notification(subject, message):
  response = sns.publish(
      TargetArn=sns_arn,
      Message=message,
      Subject=subject,
  )
