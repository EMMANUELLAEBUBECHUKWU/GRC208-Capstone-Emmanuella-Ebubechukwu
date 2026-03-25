# Deployment Guide

## GRC208 Capstone — AWS Integrated GRC Platform

**Student:** Emmanuella Ebubechukwu
**Student ID:** 2025/GRC/10041
**Course:** GRC208 — Governance, Risk, and Compliance
**Institution:** International Cybersecurity and Digital Forensics Academy (ICDFA)
**Deployed:** March 24, 2026
**Environment:** AWS Academy Learner Lab
**Region:** us-east-1 (N. Virginia)

-----

1. [Prerequisites](#prerequisites)
1. [Phase 1 — Network Infrastructure](#phase-1--network-infrastructure)
1. [Phase 2 — Database Infrastructure](#phase-2--database-infrastructure)
1. [Phase 3 — Lambda Function](#phase-3--lambda-function)
1. [Phase 4 — CloudTrail Audit Logging](#phase-4--cloudtrail-audit-logging)
1. [Phase 5 — Loading Sample Data](#phase-5--loading-sample-data)
1. [Running the Test Suite](#running-the-test-suite)
1. [Verifying the Full Deployment](#verifying-the-full-deployment)
1. [Troubleshooting](#troubleshooting)
1. [Deployed Resource Reference](#deployed-resource-reference)

-----

## Prerequisites

Before starting, make sure you have the following in place:

**AWS Access**

- AWS Academy Learner Lab access through your enrolled course
- All deployment commands run inside **AWS CloudShell** — no local software installation needed
- Confirm your credentials are active before starting any phase:

```bash
aws sts get-caller-identity
```

You should see your Account ID (975049998247) and the LabRole ARN returned. If the Learner Lab session has timed out, restart it and wait for the green indicator before continuing.

**GitHub Access**

- A GitHub account with a Personal Access Token — GitHub removed password authentication for Git operations
- Generate a token at: **GitHub → Settings → Developer Settings → Personal Access Tokens → Tokens (classic)**
- Select the `repo` scope and set an expiry of at least 30 days
- Use the token in your clone URL as shown below

**Clone the Repository**

```bash
git clone https://YOUR_TOKEN@github.com/EMMANUELLAEBUBECHUKWU/GRC208-Capstone-Emmanuella-Ebubechukwu.git
cd GRC208-Capstone-Emmanuella-Ebubechukwu
ls
```

Confirm all 17 project files are present before proceeding.

-----

## Phase 1 — Network Infrastructure

The network stack was deployed prior to this session using the `cloudformation-network-stack.yaml` template. It creates the foundational networking layer that all other resources depend on.

**Verify the stack is in place before proceeding:**

```bash
aws cloudformation describe-stacks \
  --stack-name grc-network-stack \
  --query 'Stacks[0].StackStatus'
```

Expected result: `"CREATE_COMPLETE"`

**Resources created by this stack:**

|Resource            |Details                                                                              |
|--------------------|-------------------------------------------------------------------------------------|
|VPC                 |vpc-0d9aae45de7e2ace7 (CIDR: 10.0.0.0/16)                                            |
|Public Subnet 1     |For Application Load Balancer and NAT Gateway                                        |
|Public Subnet 2     |Second AZ for high availability                                                      |
|Private Subnet 1    |subnet-0a1b4a431b6ea9a47 — for ECS, RDS, Lambda                                      |
|Private Subnet 2    |subnet-0cebfce803eaa150a — second AZ                                                 |
|Internet Gateway    |Handles inbound/outbound for public subnets                                          |
|NAT Gateway         |Allows private subnet resources to reach the internet without being reachable from it|
|Security Group (ECS)|sg-0e63951b8ee7375cd                                                                 |
|Security Group (RDS)|sg-0e9455394d5b6c9f3 — allows port 3306 from ECS security group only                 |

**Important:** The private subnet design is intentional. RDS is not reachable directly from outside the VPC. This is correct behavior, not a configuration error.

-----

## Phase 2 — Database Infrastructure

This phase deploys the RDS MySQL database, S3 storage buckets, DynamoDB tables and KMS encryption keys using the `cloudformation-database-stack.yaml` template.

**Known issues fixed before deployment:**

Two errors in the original template required fixing before the stack would deploy successfully:

1. **YAML indentation error** — The `BucketEncryption` property under the S3 bucket resource had incorrect indentation. This caused the stack to fail with a `ValidationError` on the S3 resource. Fixed by correcting the indentation level of the `ServerSideEncryptionConfiguration` block.
1. **MySQL version unavailable** — The template originally specified `EngineVersion: 8.0.35`, which is not available in the AWS Academy Learner Lab environment. Updated to `8.0.40` after running the following command to check available versions:

```bash
aws rds describe-db-engine-versions \
  --engine mysql \
  --query 'DBEngineVersions[*].EngineVersion'
```

**Deploy the database stack:**

```bash
aws cloudformation create-stack \
  --stack-name grc-database-stack \
  --template-body file://cloudformation-database-stack.yaml \
  --parameters \
    ParameterKey=DBUsername,ParameterValue=grcadmin \
    ParameterKey=DBPassword,ParameterValue=GrcPass2026! \
    ParameterKey=DBInstanceClass,ParameterValue=db.t3.micro \
  --capabilities CAPABILITY_NAMED_IAM
```

**Monitor the deployment** — RDS takes approximately 10–15 minutes:

```bash
aws cloudformation describe-stacks \
  --stack-name grc-database-stack \
  --query 'Stacks[0].StackStatus'
```

Do not proceed to Phase 3 until this returns `"CREATE_COMPLETE"`.

**If the stack fails**, check the exact error before deleting:

```bash
aws cloudformation describe-stack-events \
  --stack-name grc-database-stack \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`].[LogicalResourceId,ResourceStatusReason]' \
  --output table
```

Delete a failed stack before redeploying:

```bash
aws cloudformation delete-stack --stack-name grc-database-stack
```

Wait for deletion to complete, fix the template, then redeploy.

**Resources created by this stack:**

|Resource            |Identifier                                              |
|--------------------|--------------------------------------------------------|
|RDS MySQL 8.0.40    |grc-capstone-db                                         |
|RDS Endpoint        |grc-capstone-db.cnok20k42m82.us-east-1.rds.amazonaws.com|
|Database Name       |grcdb                                                   |
|DB Username         |grcadmin                                                |
|S3 Bucket (Evidence)|grc-capstone-evidence-bucket-975049998247               |
|S3 Bucket (Reports) |grc-capstone-compliance-reports-975049998247            |
|DynamoDB Table      |grc-compliance-status                                   |
|DynamoDB Table      |grc-controls                                            |
|DynamoDB Table      |grc-risk-register                                       |
|KMS Key             |RDS encryption                                          |
|KMS Key             |S3 encryption                                           |

-----

## Phase 3 — Lambda Function

The compliance monitor Lambda function needs to be packaged with `pymysql` because the default Lambda Python runtime does not include it. Without this library, the function cannot communicate with the RDS database.

**Package the function with its dependency:**

```bash
pip install pymysql -t ./package/
cp lambda_compliance_monitor.py ./package/
cd package
zip -r ../lambda_function.zip .
cd ..
```

**Deploy the Lambda function:**

```bash
aws lambda create-function \
  --function-name grc-compliance-monitor \
  --runtime python3.9 \
  --role arn:aws:iam::975049998247:role/LabRole \
  --handler lambda_compliance_monitor.lambda_handler \
  --zip-file fileb://lambda_function.zip \
  --timeout 300 \
  --memory-size 256
```

**Confirm the function is active:**

```bash
aws lambda get-function \
  --function-name grc-compliance-monitor \
  --query 'Configuration.State'
```

Expected result: `"Active"`

-----

## Phase 4 — CloudTrail Audit Logging

CloudTrail records every API call made in the AWS account. Before the trail can be created, the S3 bucket needs a policy that allows CloudTrail to write to it.

**Add the required bucket policy:**

```bash
aws s3api put-bucket-policy \
  --bucket grc-capstone-compliance-reports-975049998247 \
  --policy '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "AWSCloudTrailAclCheck",
        "Effect": "Allow",
        "Principal": {"Service": "cloudtrail.amazonaws.com"},
        "Action": "s3:GetBucketAcl",
        "Resource": "arn:aws:s3:::grc-capstone-compliance-reports-975049998247"
      },
      {
        "Sid": "AWSCloudTrailWrite",
        "Effect": "Allow",
        "Principal": {"Service": "cloudtrail.amazonaws.com"},
        "Action": "s3:PutObject",
        "Resource": "arn:aws:s3:::grc-capstone-compliance-reports-975049998247/AWSLogs/975049998247/*",
        "Condition": {
          "StringEquals": {
            "s3:x-amz-acl": "bucket-owner-full-control"
          }
        }
      }
    ]
  }'
```

**Create the audit trail:**

```bash
aws cloudtrail create-trail \
  --name grc-audit-trail \
  --s3-bucket-name grc-capstone-compliance-reports-975049998247
```

**Start logging:**

```bash
aws cloudtrail start-logging --name grc-audit-trail
```

**Verify logging is active:**

```bash
aws cloudtrail get-trail-status \
  --name grc-audit-trail \
  --query 'IsLogging'
```

Expected result: `true`

**Note on AWS Config:** The AWS Config delivery channel could not be configured in this environment. The LabRole does not have sufficient permissions for the `config:PutDeliveryChannel` action. This is a known Learner Lab sandbox restriction and does not affect the core functionality of the platform. CloudTrail covers the audit logging requirement.

-----

## Phase 5 — Loading Sample Data

RDS is deployed in a private subnet and is not reachable directly from AWS CloudShell. To load data into the database, a second Lambda function was created specifically to run inside the VPC and connect to RDS from within the private network.

**Package the data loader with pymysql:**

```bash
pip install pymysql -t ./loader-package/
cp load_sql.py ./loader-package/
cd loader-package
zip -r ../load_db.zip .
cd ..
```

**Create the VPC-connected loader Lambda:**

```bash
aws lambda create-function \
  --function-name grc-db-loader \
  --runtime python3.9 \
  --role arn:aws:iam::975049998247:role/LabRole \
  --handler load_sql.lambda_handler \
  --zip-file fileb://load_db.zip \
  --timeout 60 \
  --vpc-config SubnetIds=subnet-0a1b4a431b6ea9a47,subnet-0cebfce803eaa150a,SecurityGroupIds=sg-0e63951b8ee7375cd
```

**Invoke the function to load all sample data:**

```bash
aws lambda invoke \
  --function-name grc-db-loader \
  --payload '{}' \
  response.json && cat response.json
```

Expected result: `statusCode: 200` with the four table names listed — `frameworks`, `controls`, `risks`, `audit_logs`

**Data loaded into grcdb:**

|Table     |Records                                             |
|----------|----------------------------------------------------|
|frameworks|6 (ISO 27001, NIST CSF, PCI DSS, HIPAA, GDPR, SOC 2)|
|controls  |10 sample controls linked to frameworks             |
|risks     |6 sample risks with probability, impact and scores  |
|audit_logs|5 initial audit entries                             |

-----

## Running the Test Suite

```bash
pip install pytest boto3 --quiet
python3 test_cases.py
```

Expected result:

```
Ran 22 tests in 0.001s
OK
```

All 22 tests across 6 categories should pass with zero failures. If any test fails, check that the sample data loaded correctly in Phase 5 before investigating further.

-----

## Verifying the Full Deployment

Run these four commands to confirm all components are in place:

```bash
# Both stacks should show CREATE_COMPLETE
aws cloudformation describe-stacks \
  --query 'Stacks[*].[StackName,StackStatus]' \
  --output table

# Three DynamoDB tables should be listed
aws dynamodb list-tables

# RDS should show available
aws rds describe-db-instances \
  --query 'DBInstances[0].DBInstanceStatus'

# CloudTrail should be logging
aws cloudtrail get-trail-status \
  --name grc-audit-trail \
  --query 'IsLogging'
```

-----

## Troubleshooting

### CloudFormation stack keeps rolling back

Run this command immediately after the failure — before deleting the stack — to see the exact cause:

```bash
aws cloudformation describe-stack-events \
  --stack-name grc-database-stack \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`].[LogicalResourceId,ResourceStatusReason]' \
  --output table
```

Common causes encountered during this deployment:

- **YAML indentation errors** — check the BucketEncryption block carefully. One wrong indentation level breaks the entire stack
- **MySQL version not available** — run `describe-db-engine-versions` to find the correct version for your environment
- **Insufficient permissions** — the LabRole has limited permissions. Some resources may not be deployable in the Learner Lab sandbox

-----

### GitHub authentication fails when cloning

GitHub no longer accepts account passwords for Git. Generate a Personal Access Token and embed it in the clone URL:

```bash
git clone https://YOUR_TOKEN@github.com/EMMANUELLAEBUBECHUKWU/...
```

-----

### Lambda cannot connect to RDS

RDS is in a private subnet — it cannot be reached from CloudShell directly. This is intentional. Use the `grc-db-loader` VPC-connected Lambda to interact with the database from within the private network.

-----

### Lambda crashes with ModuleNotFoundError: pymysql

The pymysql library must be packaged with the function code before deployment. It is not included in the default Lambda Python runtime. Follow the packaging steps in Phase 3 and Phase 5 to zip it together with your function code before deploying.

-----

### CloudTrail trail creation fails

The S3 bucket policy must be in place before creating the trail. If you skipped the `put-bucket-policy` step or it returned an error, apply the policy first and then retry `create-trail`.

-----

### Learner Lab session expires mid-deployment

If the lab times out during deployment, restart it and check which phases completed before continuing. Do not redeploy a phase that already shows `CREATE_COMPLETE` in CloudFormation — it will fail with a `AlreadyExistsException`.

-----

## Deployed Resource Reference

|Resource            |Identifier                                              |
|--------------------|--------------------------------------------------------|
|VPC                 |vpc-0d9aae45de7e2ace7                                   |
|Private Subnet 1    |subnet-0a1b4a431b6ea9a47                                |
|Private Subnet 2    |subnet-0cebfce803eaa150a                                |
|ECS Security Group  |sg-0e63951b8ee7375cd                                    |
|RDS Security Group  |sg-0e9455394d5b6c9f3                                    |
|RDS Endpoint        |grc-capstone-db.cnok20k42m82.us-east-1.rds.amazonaws.com|
|Lambda Function     |grc-compliance-monitor                                  |
|Lambda (Data Loader)|grc-db-loader                                           |
|CloudTrail          |grc-audit-trail                                         |
|S3 Evidence Bucket  |grc-capstone-evidence-bucket-975049998247               |
|S3 Reports Bucket   |grc-capstone-compliance-reports-975049998247            |
|DynamoDB Table 1    |grc-compliance-status                                   |
|DynamoDB Table 2    |grc-controls                                            |
|DynamoDB Table 3    |grc-risk-register                                       |
|IAM Role            |arn:aws:iam::975049998247:role/LabRole                  |
