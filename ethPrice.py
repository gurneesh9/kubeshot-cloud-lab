import json
import csv
import requests
import boto3

# Replace these with your AWS credentials and S3 bucket name
aws_access_key_id = 'YOUR_ACCESS_KEY'
aws_secret_access_key = 'YOUR_SECRET_KEY'
bucket_name = 'data_bucket'

# Fetch Ethereum price history JSON data from CoinGecko
coin_gecko_url = 'https://api.coingecko.com/api/v3/coins/ethereum/market_chart?vs_currency=usd&days=30'
response = requests.get(coin_gecko_url)
data = response.json()

# Extract the price history
ethereum_price_history = []
for timestamp, price in zip(data['timestamps'], data['prices']):
    ethereum_price_history.append({'timestamp': timestamp, 'price': price})

# Convert JSON data to CSV format
csv_filename = 'ethereum_price_history.csv'
with open(csv_filename, mode='w', newline='') as csv_file:
    fieldnames = ['timestamp', 'price']
    writer = csv.DictWriter(csv_file, fieldnames=fieldnames)
    writer.writeheader()
    writer.writerows(ethereum_price_history)

# Upload the CSV file to S3
s3 = boto3.client('s3', aws_access_key_id=aws_access_key_id, aws_secret_access_key=aws_secret_access_key)
s3.upload_file(csv_filename, bucket_name, csv_filename)

print(f"CSV file '{csv_filename}' uploaded to S3 bucket '{bucket_name}'")
