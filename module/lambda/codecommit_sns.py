import boto3, os, json
from pprint import pprint


def aws_session(role_arn, session_name, region_name):

    client = boto3.client('sts')

    response = client.assume_role(
        RoleArn=role_arn,
        RoleSessionName=session_name
    )

    return boto3.Session(
        aws_access_key_id=response['Credentials']['AccessKeyId'],
        aws_secret_access_key=response['Credentials']['SecretAccessKey'],
        aws_session_token=response['Credentials']['SessionToken'],
        region_name=region_name
        )

def lambda_handler(event, context):
    try:
        role_arn = "arn:aws:iam::{0}:role/{1}".format(os.environ['TF_ACCOUNT_ID'], "SNS_lambda_role")
        role_session_name = "{0}-{1}".format(os.environ['TF_ACCOUNT_ID'], context.function_name)

        lambda_session = aws_session(role_arn, role_session_name, os.environ['PL_REGION'])

        topicArn = ###### ADD HERE THE TOPICARN YOU WANT TO USE 

        sns = lambda_session.client('sns')

        response = sns.publish(
            TopicArn = topicArn,
            Message = "{0}\n\n{1}\n\n{2}\n\n{3}\n\n".format(event['detail']['event'], event['detail']['lastModifiedDate'], event['detail']['notificationBody'], event['detail']['description']),
            Subject = "{0} - {1} ({2})".format(event['detail-type'], event['detail']['pullRequestStatus'], event['region'])
        )


    except Exception as e:
        print(e)
        return {
            "Function Name": context.function_name,
            "Invoked Function arn": context.invoked_function_arn,
            "AWS Request Id": context.aws_request_id,
            "Error": str(e)
        }
    else:
        print("OK")
