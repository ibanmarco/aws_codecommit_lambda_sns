# aws_codecommit_lambda_sns

![Minimal Screenshot](img/diagram.png)

This code will deploy a lambda function that will call SNS to email notification everytime that a pull request or merge is done. Basically, once a pull request or merge is done, a CloudWatch rule will be trigged and the lambda function will be invoked.

You can see the codecommit events through CloudTrail using the follow command where $PROFILE is the profile you are using and $EPOCH_TIMESTAMP is the date in epoch.

```bash
aws --profile $PROFILE cloudtrail lookup-events --lookup-attributes AttributeKey=EventSource,AttributeValue=codecommit.amazonaws.com --start-time $EPOCH_TIMESTAMP --end-time $EPOCH_TIMESTAMP --max-results 10
```

- This code has been created to be used with the profile configured on ~/.aws/credentials. You can easily modify this code to assume a role if you are using a Pipeline with cross-accounts and also add a buildspec file to perform this code.
- PL* variables should be passed from each stage of the Pipeline.
