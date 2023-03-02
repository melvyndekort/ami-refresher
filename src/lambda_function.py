import os
import logging
import requests
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

client = boto3.client('ec2')

def lambda_handler(event, context):
  ami_id = get_ami_id(os.environ['AMI_PARAM_PATH_X86'])
  update_launch_template('lmgateway-x86', ami_id)

  ami_id = get_ami_id(os.environ['AMI_PARAM_PATH_ARM64'])
  update_launch_template('lmgateway-arm', ami_id)

  terminate_instances()


def get_ami_id(param_name):
  url = f'http://localhost:2773/systemsmanager/parameters/get?name={param_name}'
  headers = {'X-Aws-Parameters-Secrets-Token': os.environ['AWS_SESSION_TOKEN']}
  param = requests.get(url, headers=headers).json()

  logger.info('Retrieved AMI_ID from parameter store:', param['Parameter']['Value'])
  return param['Parameter']['Value']


def update_launch_template(template_name, ami_id):
  response = client.describe_launch_templates(
    LaunchTemplateNames = [template_name]
  )
  logger.debug(response)

  launchTemplateId = response['LaunchTemplates'][0]['LaunchTemplateId']
  logger.info('Launch Template ID:', launchTemplateId)

  response = client.create_launch_template_version(
    LaunchTemplateId = launchTemplateId,
    SourceVersion = response['LaunchTemplates'][0]['DefaultVersionNumber'],
    LaunchTemplateData={
      'ImageId': ami_id
    }
  )
  logger.debug(response)

  response = client.modify_launch_template(
    LaunchTemplateId = launchTemplateId,
    DefaultVersion = response['LaunchTemplateVersion']['VersionNumber']
  )
  logger.debug(response)


def terminate_instances():
  response = client.describe_instances(
    Filters=[
      {
        'Name': 'tag:Name',
        'Values': ['lmgateway']
      },
      {
        'Name': 'instance-state-name',
        'Values': ['running']
      }
    ]
  )
  logger.debug(response)

  instanceId = response['Reservations'][0]['Instances'][0]['InstanceId']
  logger.info('Terminating instance:', instanceId)

  response = client.terminate_instances(
    InstanceIds=[instanceId]
  )
  logger.debug(response)

def main():
    os.environ['AMI_PARAM_PATH_X86']   = '/aws/service/ami-amazon-linux-latest/al2022-ami-minimal-kernel-default-x86_64'
    os.environ['AMI_PARAM_PATH_ARM64'] = '/aws/service/ami-amazon-linux-latest/al2022-ami-minimal-kernel-default-arm64'

if __name__ == "__main__":
    main()
