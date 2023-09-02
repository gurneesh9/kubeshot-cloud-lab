import boto3

def send_sns_sms_notification(topic_arn, message, phone_number):
    sns = boto3.client('sns')

    # Publish the SMS message to the specified SNS topic
    response = sns.publish(
        TopicArn=topic_arn,
        Message=message,
        MessageStructure='string',
        PhoneNumber=phone_number
    )

    return response

def lambda_handler(event, context):
    # Replace 'TOPIC_ARN' 
    topic_arn = 'YOUR_TOPIC_ARN'
    
    message = "Hello, this is an SMS notification from your Lambda function! Quicksight report is saved"
    
    phone_number = 'PHONE_NUMBER'

    # Send the SMS notification
    response = send_sns_sms_notification(topic_arn, message, phone_number)

    return {
        'statusCode': 200,
        'body': json.dumps('SMS Notification sent successfully!')
    }
