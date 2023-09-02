# Exporting quicksight file to s3 (It will be used inside data processing lambda only)

import boto3

def export_quicksight_report():
    quicksight = boto3.client('quicksight')

    # Replace with the ARN of the report/dashboard you want to export
    report_arn = 'arn:aws:quicksight:us-east-1:your-account-id:report/report-id'

    # Configure the export parameters
    export_config = {
        'S3Destination': {
            'Bucket': 'your-s3-bucket',
            'Prefix': 'exports/',
        },
        'AdhocFilteringOption': {
            'AvailabilityStatus': 'DISABLED'
        },
        'FileFormat': 'CSV',  # Change to the desired format (CSV, PDF, etc.)
    }

    response = quicksight.generate_presigned_url(
        AwsAccountId='your-account-id',
        SessionLifetimeInMinutes=600,  # Set an appropriate lifetime
        Namespace='default',  # Namespace for the report/dashboard
        ReportId='report-id',  # Replace with your report/dashboard ID
        IdentityType='IAM',
        SessionTags=[
            {
                'Key': 'string',
                'Value': 'string'
            },
        ],
        DurationSeconds=3600,  # Set an appropriate duration
        PreSignedUrlConfig={
            'RoleArn': 'arn:aws:iam::your-account-id:role/service-role/your-role-name',  # Replace with your role ARN
            'ExpiresIn': 3600,  # Set an appropriate expiration time
        },
        Format='CSV',  # Change to the desired format (CSV, PDF, etc.)
        SourceEntity={
            'SourceTemplate': {
                'DataSetReferences': [
                    {
                        'DataSetArn': 'arn:aws:quicksight:us-east-1:your-account-id:dataset/dataset-id',  # Replace with your dataset ARN
                        'DataSetPlaceholder': 'string',
                    },
                ],
            },
        },
        Destinations=[
            {
                'S3Destination': {
                    'Bucket': 'your-s3-bucket',
                    'Prefix': 'exports/',  # Customize the S3 object path
                },
            },
        ],
    )

    return response
