# GRC208 Capstone Project - AWS Integrated GRC Platform

## Student Information
- *Name:* Emmanuella Ebubechukwu
- *Student ID:* 2025/GRC/10041
- *Course:* GRC208 - Governance, Risk, and Compliance
- *Institution:* International Cybersecurity and Digital Forensics Academy (ICDFA)
- *Date Deployed:* March 24, 2026
- *Environment:* AWS Academy Learner Lab
- *Region:* us-east-1

-----

## Project Overview

This capstone project is a fully deployed, enterprise-grade
Governance, Risk, and Compliance platform built on Amazon Web
Services. It was designed to solve a real problem: organizations
that manage compliance manually across multiple frameworks have
no reliable way to monitor their posture in real time, respond
to violations quickly, or produce audit evidence on demand.

The platform addresses this by automating compliance monitoring
using AWS Config, calculating risk scores continuously using
AWS Lambda, storing all GRC data in a structured RDS MySQL
database, and alerting the team through CloudWatch and SNS
when the risk score crosses a defined threshold. A React
dashboard gives users a live view of compliance status without
running a single manual check.

Everything in this project was deployed from scratch using
Infrastructure as Code. The entire platform can be redeployed
to any AWS account in under 40 minutes using the CloudFormation
templates and deployment guide in this repository.

-----

## Deployment Status

All five deployment phases completed successfully on
March 24, 2026:

|Phase  |Description                            |Status                  |
|-------|---------------------------------------|------------------------|
|Phase 1|Network Stack (VPC, subnets, gateways) |CREATE_COMPLETE         |
|Phase 2|Database Stack (RDS, S3, DynamoDB, KMS)|CREATE_COMPLETE         |
|Phase 3|Lambda Compliance Monitor              |Deployed                |
|Phase 4|CloudTrail Audit Logging               |Active (IsLogging: true)|
|Phase 5|Sample Data Loading                    |4 tables, 50+ records   |
|Tests  |Automated Test Suite                   |22/22 Passing           |

-----

## Quick Start

### Requirements

- AWS Academy Learner Lab access
- AWS CloudShell (no local installation needed)
- GitHub Personal Access Token for repository access

### Clone the Repository

```bash
git clone https://YOUR_TOKEN@github.com/EMMANUELLAEBUBECHUKWU/GRC208-Capstone-Emmanuella-Ebubechukwu.git
cd GRC208-Capstone-Emmanuella-Ebubechukwu
```

### Deploy the Platform

Follow the five phases in DEPLOYMENT_GUIDE.md in order.
Each phase must reach its expected state before the next
begins.

```bash
# Verify network stack is ready
aws cloudformation describe-stacks \
  --stack-name grc-network-stack \
  --query 'Stacks[0].StackStatus'

# Deploy database stack
aws cloudformation create-stack \
  --stack-name grc-database-stack \
  --template-body file://cloudformation-database-stack.yaml \
  --parameters \
    ParameterKey=DBUsername,ParameterValue=grcadmin \
    ParameterKey=DBPassword,ParameterValue=GrcPass2026! \
    ParameterKey=DBInstanceClass,ParameterValue=db.t3.micro \
  --capabilities CAPABILITY_NAMED_IAM
```

### Run the Tests

```bash
python3 test_cases.py
```

Expected result: Ran 22 tests in 0.001s – OK

-----

## Architecture Overview

The platform runs entirely within an AWS VPC
(vpc-0d9aae45de7e2ace7, CIDR: 10.0.0.0/16) with public and
private subnets across two availability zones.

**Public subnets** host the Application Load Balancer and
NAT Gateway.

**Private subnets** host all compute and data resources:

- ECS Fargate runs the GRC web application
- RDS MySQL 8.0.40 stores all structured GRC data
- Lambda functions handle compliance monitoring and data loading

**Supporting services** running alongside the VPC:

- AWS Config evaluates resource compliance continuously
- CloudTrail (grc-audit-trail) logs every API call
- DynamoDB serves real-time compliance status to the dashboard
- S3 stores evidence documents and audit logs
- CloudWatch and SNS handle monitoring and alerting
- KMS encrypts all data at rest

For full architecture details see architecture_design.md.

-----

## Compliance Frameworks Supported

This platform supports six major compliance frameworks:

|Framework                   |Focus Area                     |
|----------------------------|-------------------------------|
|ISO 27001:2022              |Information security management|
|NIST Cybersecurity Framework|Cybersecurity risk management  |
|PCI DSS 3.2.1               |Payment card data protection   |
|HIPAA                       |Health information protection  |
|GDPR                        |Personal data protection (EU)  |
|SOC 2                       |Service organization controls  |

-----

## AWS Resources Deployed

|Resource            |Identifier                                              |
|--------------------|--------------------------------------------------------|
|VPC                 |vpc-0d9aae45de7e2ace7                                   |
|RDS MySQL 8.0.40    |grc-capstone-db                                         |
|RDS Endpoint        |grc-capstone-db.cnok20k42m82.us-east-1.rds.amazonaws.com|
|Lambda (Monitor)    |grc-compliance-monitor                                  |
|Lambda (Data Loader)|grc-db-loader                                           |
|CloudTrail          |grc-audit-trail                                         |
|S3 Evidence Bucket  |grc-capstone-evidence-bucket-975049998247               |
|S3 Reports Bucket   |grc-capstone-compliance-reports-975049998247            |
|DynamoDB Table 1    |grc-compliance-status                                   |
|DynamoDB Table 2    |grc-controls                                            |
|DynamoDB Table 3    |grc-risk-register                                       |
|Private Subnet 1    |subnet-0a1b4a431b6ea9a47                                |
|Private Subnet 2    |subnet-0cebfce803eaa150a                                |

-----

## Repository Contents

|File                              |Purpose                                     |
|----------------------------------|--------------------------------------------|
|README.md                         |This file                                   |
|DEPLOYMENT_GUIDE.md               |Step-by-step deployment with troubleshooting|
|BEST_PRACTICES.md                 |AWS, security and compliance guidance       |
|AWS_SERVICES_GUIDE.md             |Detailed service explanations               |
|architecture_design.md            |System architecture and design decisions    |
|PROJECT_MANIFEST.md               |Complete file inventory and relationships   |
|cloudformation-network-stack.yaml |Network infrastructure template             |
|cloudformation-database-stack.yaml|Database infrastructure template            |
|lambda_compliance_monitor.py      |Compliance monitoring Lambda function       |
|load_sql.py                       |VPC Lambda data loader                      |
|grc-dashboard.jsx                 |React frontend dashboard                    |
|grc-dashboard.css                 |Dashboard styling                           |
|test_cases.py                     |22 automated tests                          |
|sample_data.sql                   |Sample GRC data (50+ records)               |
|deploy.sh                         |Deployment automation script                |
|response.json                     |Lambda invocation response                  |

-----

## Learning Outcomes

This project provided hands-on experience across four areas:

**Cloud Architecture**
Designing a multi-tier AWS architecture with public and private
subnets, understanding why databases belong in private subnets,
and learning how NAT Gateway enables private resources to reach
the internet without being exposed to inbound connections.

**AWS Services**
Deploying and configuring Lambda, RDS, S3, DynamoDB,
CloudTrail, CloudWatch and KMS through real deployment tasks
rather than guided tutorials. This included debugging five
CloudFormation rollbacks, fixing YAML template errors and
solving VPC connectivity challenges.

**Infrastructure as Code**
Writing and debugging CloudFormation templates, using
describe-stack-events to diagnose failures, and maintaining
version-controlled infrastructure that can be redeployed
reliably from scratch.

**Security and Compliance**
Implementing encryption at rest and in transit, using IAM
roles with no hardcoded credentials, configuring audit logging
at both the infrastructure and application level, and mapping
technical controls to six compliance frameworks.

-----

## Known Learner Lab Limitations

The AWS Academy Learner Lab environment has two restrictions
that do not exist in a standard AWS account:

1. The AWS Config delivery channel cannot be created because
   the LabRole lacks the config:PutDeliveryChannel permission.
   CloudTrail serves as the compensating audit control.
1. RDS is not directly reachable from CloudShell due to
   private subnet placement. The grc-db-loader Lambda function
   was created to solve this by connecting to RDS from inside
   the VPC.

Both limitations are documented in DEPLOYMENT_GUIDE.md.
