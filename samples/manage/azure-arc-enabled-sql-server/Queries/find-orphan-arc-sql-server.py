
#
#Prereqs

#Step 1: Assign Required Permissions to the Azure AD Application
#1.	Navigate to the Azure portal: Azure Portal
#2.	Go to "Azure Active Directory" > "App registrations" > Select your application (ie dknadmin-sp).
#3.	Go to "API permissions" > "Add a permission".
#4.	Select "Azure Service Management".
#5.	Select "Delegated permissions" and check user_impersonation.
#6.	Click "Add permissions".
#7.	Click on "Grant admin consent for [Your Organization]" and confirm.
#Step 2: Assign the Service Principal to a Role in Your Subscription
#1.	Navigate to the Azure portal: Azure Portal
#2.	Go to "Subscriptions" and select your subscription (0e7c68e3-ddc7-4979-bdc2-30a14addf264).
#3.	Click on "Access control (IAM)".
#4.	Click on "Add role assignment".
#5.	Select a role that has permissions to read resources, such as "Reader".
#6.	In the "Select" field, search for your registered application (dknadmin-sp) and select it.
#7.	Click "Save".


import requests
import json
from pyspark.sql.types import StructType, StructField, StringType

# Retrieve secrets from Databricks
tenant_id = dbutils.secrets.get(scope="azure_scope", key="tenant_id")
client_id = dbutils.secrets.get(scope="azure_scope", key="client_id")
client_secret = dbutils.secrets.get(scope="azure_scope", key="client_secret")

# or explicitly specify
#tenant_id = ‘<tenant>’
#client_id = ‘<clientid>’
#client_secret = ‘<clientsecret>’

scope = 'https://management.azure.com/.default'
token_url = f'https://login.microsoftonline.com/{tenant_id}/oauth2/v2.0/token'

token_data = {
    'grant_type': 'client_credentials',
    'client_id': client_id,
    'client_secret': client_secret,
    'scope': scope
}

# Get the access token
token_response = requests.post(token_url, data=token_data)
token_response_json = token_response.json()

if 'access_token' not in token_response_json:
    print("Failed to get access token")
    print(token_response_json)
    dbutils.notebook.exit("Failed to get access token")

token = token_response_json['access_token']

headers = {
    "Authorization": f"Bearer {token}",
    "Content-Type": "application/json"
}

payload = {
    "subscriptions": [
        "0e7c68e3-ddc7-4979-bdc2-30a14addf264"
    ],
    "query": "resources | where type =~ 'microsoft.azurearcdata/sqlserverinstances' | extend ARCMachineName = tostring(properties['containerResourceId']) | project name, type, subscriptionId, ARCMachineName, properties"
}

response = requests.post(
    "https://management.azure.com/providers/Microsoft.ResourceGraph/resources?api-version=2021-03-01",
    headers=headers,
    data=json.dumps(payload)
)

if response.status_code == 200:
    print("Success")
    response_json = response.json()
    
    # Prepare data for DataFrame
    data = []
    for item in response_json['data']:
        row = {
            'Name': item['name'],
            'Type': item['type'],
            'Subscription ID': item['subscriptionId'],
            'ARC Machine Name': item['ARCMachineName'],
            'Properties': json.dumps(item['properties'], indent=4)
        }
        data.append(row)
    
    # Define schema
    schema = StructType([
        StructField("Name", StringType(), True),
        StructField("Type", StringType(), True),
        StructField("Subscription ID", StringType(), True),
        StructField("ARC Machine Name", StringType(), True),
        StructField("Properties", StringType(), True)
    ])
    
    # Create DataFrame
    df = spark.createDataFrame(data, schema)
    
    # Display DataFrame
    display(df)
    
    # Optionally save to a CSV file
    df.write.csv('/dbfs/tmp/output.csv', header=True, mode='overwrite')
else:
    print(f"Failed with status code {response.status_code}")
    print(response.text)
    dbutils.notebook.exit("Failed with status code {response.status_code}")
