# AWS Services Guide

## GRC208 Capstone: AWS Integrated GRC Platform

## Student Information
- **Name:** Emmanuella Ebubechukwu
- **Student ID:** 2025/GRC/10041
- **Course:** GRC208 - Governance, Risk, and Compliance
- **Institution:** International Cybersecurity and Digital Forensics Academy (ICDFA)
- **Date Deployed:** March 24, 2026
- **Environment:** AWS Academy Learner Lab
- **Region:** us-east-1 (N. Virginia)
-----

## AWS CloudFormation

### What It Does in This Platform

CloudFormation is the tool used to define and deploy all
infrastructure in this project. Instead of clicking through
the AWS Console to create resources one by one, every resource
is described in YAML template files. CloudFormation reads those
files and builds everything in the correct order, handling
dependencies automatically.

Two stacks were deployed for this project:

- **grc-network-stack** using cloudformation-network-stack.yaml
- **grc-database-stack** using cloudformation-database-stack.yaml

### Integration Pattern

The network stack must reach CREATE_COMPLETE before the database
stack is deployed, because the database stack references outputs
from the network stack such as subnet IDs and security group IDs.
CloudFormation cross-stack references handle this dependency.

### Performance Considerations

CloudFormation itself has no performance impact on the running
platform. It is only active during deployment and updates. The
database stack takes approximately 15 minutes to complete because
RDS provisioning is the slowest step in the process.

### Cost Considerations

CloudFormation has no additional cost. You pay only for the
resources it creates, not for the service that creates them.

-----

## Amazon VPC

### What It Does in This Platform

The VPC (vpc-0d9aae45de7e2ace7) is the private network that
contains all platform resources. It uses the CIDR block
10.0.0.0/16, which provides 65,536 possible IP addresses across
all subnets.

The VPC is divided into public and private subnets:

- Public subnets host the Application Load Balancer and NAT
  Gateway, which handle traffic entering and leaving the network
- Private subnets host RDS, ECS and Lambda, which have no
  direct internet access

### Integration Pattern

Every other service in this platform sits inside this VPC.
Security groups act as virtual firewalls controlling which
services can communicate with which. The RDS security group
only accepts connections from the ECS security group on port
3306, which means the database is only reachable from the
application layer.

### Performance Considerations

Placing resources in the same VPC and the same region minimizes
network latency between services. Lambda functions configured
with VPC access take slightly longer to start up on their first
invocation because they need to attach to the network interface.
This is a known trade-off when connecting Lambda to private
resources like RDS.

### Cost Considerations

The NAT Gateway is the most significant networking cost in this
architecture. NAT Gateway charges apply per hour and per GB of
data processed. In a cost-conscious production environment,
Lambda functions that only need to reach AWS services (not the
internet) can use VPC endpoints instead of routing through the
NAT Gateway, which reduces both cost and latency.

-----

## Amazon RDS MySQL

### What It Does in This Platform

RDS hosts the primary relational database (grcdb) for the GRC
platform. It stores six tables of structured GRC data:
frameworks, controls, risks, assets, compliance_status and
audit_logs. These tables have foreign key relationships between
them, which is why a relational database was the right choice
for this data.

The instance runs MySQL 8.0.40 on a db.t3.micro instance class,
deployed in the private subnet with the endpoint:
grc-capstone-db.cnok20k42m82.us-east-1.rds.amazonaws.com

### Integration Pattern

RDS is not accessible directly from outside the VPC. The GRC
application running on ECS Fargate connects to it through the
private network. The grc-db-loader Lambda function also connects
to it from inside the VPC to load and manage sample data.
CloudShell and any external tool cannot reach RDS directly by
design.

### Performance Considerations

The db.t3.micro instance class is appropriate for development
and testing workloads. For a production deployment handling
multiple concurrent users and continuous compliance checks,
db.t3.small or db.t3.medium would be more suitable. Multi-AZ
deployment can be enabled to provide automatic failover if the
primary instance becomes unavailable, though this was set to
false in the Learner Lab to reduce provisioning time.

### Cost Considerations

RDS is the most expensive resource in this deployment. The
db.t3.micro instance falls within the AWS Free Tier for the
first 12 months on a new account, providing 750 hours per month
at no charge. Beyond the Free Tier, costs accrue hourly.
Stopping the instance when not in use reduces costs
significantly during development.

-----

## AWS Lambda

### What It Does in This Platform

Two Lambda functions were deployed for this project:

**grc-compliance-monitor** is the main compliance monitoring
function. It is triggered by AWS Config when resource compliance
changes, calculates the risk score based on the ratio of
non-compliant rules, stores the result in DynamoDB and RDS, and
triggers an SNS notification if the score exceeds 7.0.

**grc-db-loader** is a utility function created specifically to
load sample data into the RDS database from inside the VPC.
Because RDS is in a private subnet with no direct external
access, this function serves as the bridge between CloudShell
commands and the database.

Both functions run Python 3.9 and use the pymysql library, which
must be packaged with the function code before deployment because
it is not included in the default Lambda runtime.

### Integration Pattern

grc-compliance-monitor connects to DynamoDB and RDS to write
results, and to SNS to send alerts. It is configured with VPC
access so it can reach the private RDS instance. grc-db-loader
is also VPC-connected and uses the same private subnet
configuration (subnet-0a1b4a431b6ea9a47,
subnet-0cebfce803eaa150a) with the ECS security group
(sg-0e63951b8ee7375cd).

### Performance Considerations

Lambda functions with VPC access experience a cold start delay
on their first invocation. After the first execution,
subsequent invocations are faster because the network interface
remains attached. For the compliance monitor, which runs in
response to Config events rather than on a tight schedule,
this delay is acceptable.

Memory is set to 256 MB and timeout to 300 seconds for the
compliance monitor. The data loader uses 60 seconds because
the SQL loading operation completes well within that window.

### Cost Considerations

Lambda pricing is based on the number of invocations and the
duration of each execution. The AWS Free Tier includes one
million invocations and 400,000 GB-seconds of compute per month.
For a GRC platform at this scale, Lambda costs are negligible.
The compliance monitor only runs when Config detects a change,
not on a continuous loop, which keeps invocation counts low.

-----

## Amazon S3

### What It Does in This Platform

Two S3 buckets were created for this project:

**grc-capstone-evidence-bucket-975049998247** stores compliance
evidence documents uploaded during assessments and audits.
Versioning is enabled so every version of every document is
preserved and can be retrieved if needed.

**grc-capstone-compliance-reports-975049998247** stores
generated compliance reports and also receives CloudTrail audit
logs. The bucket policy was configured to allow CloudTrail to
write log files into an AWSLogs prefix.

Both buckets use server-side encryption with AWS KMS keys.

### Integration Pattern

CloudTrail writes directly to the compliance reports bucket
using the bucket policy configured in Phase 4. The GRC
application uploads evidence documents to the evidence bucket
through the application layer. Both buckets have versioning
enabled, so uploads create new versions rather than overwriting
existing files.

### Performance Considerations

S3 provides essentially unlimited throughput for typical GRC
workloads. Evidence uploads and log writes are infrequent
compared to database operations, so S3 performance is not a
bottleneck in this architecture.

### Cost Considerations

S3 charges for storage volume, number of requests and data
transfer out. The AWS Free Tier includes 5 GB of standard
storage, 20,000 GET requests and 2,000 PUT requests per month.
For a development GRC platform with limited data, S3 costs are
minimal. In production, S3 Lifecycle policies can move older
evidence documents to cheaper storage classes like S3 Glacier
after a set number of days to reduce long-term storage costs.

-----

## Amazon DynamoDB

### What It Does in This Platform

Three DynamoDB tables store real-time compliance data:

**grc-compliance-status** holds the current compliance
percentage and rule counts, updated every time the compliance
monitor Lambda function runs.

**grc-controls** stores the current status of each control,
updated when the compliance state of associated resources changes.

**grc-risk-register** holds the current risk scores and levels,
updated alongside compliance status after each evaluation.

All three tables are in Active status and were verified in the
AWS Console after deployment.

### Integration Pattern

The compliance monitor Lambda writes to all three tables
immediately after calculating results. The React dashboard
reads from these tables to display real-time status without
querying RDS, which would be slower for frequently accessed
data. RDS stores the historical record while DynamoDB serves
the live view.

### Performance Considerations

DynamoDB provides single-digit millisecond read and write
performance at any scale. For dashboard reads that happen every
time a user loads the compliance status page, this is faster
than querying RDS. The tables use on-demand capacity mode,
which means AWS handles scaling automatically without requiring
provisioned throughput settings.

### Cost Considerations

DynamoDB on-demand mode charges per read and write request
unit. The AWS Free Tier includes 25 GB of storage and 25
provisioned capacity units per month indefinitely. For this
platform at development scale, DynamoDB costs are effectively
zero within the Free Tier limits.

-----

## AWS CloudTrail

### What It Does in This Platform

CloudTrail (grc-audit-trail) records every API call made in
the AWS account. This includes every CloudFormation action,
every Lambda invocation, every S3 operation and every RDS
management call. Log files are delivered to the compliance
reports S3 bucket.

IsLogging was confirmed as true after deployment using:

```bash
aws cloudtrail get-trail-status \
  --name grc-audit-trail \
  --query 'IsLogging'
```

### Integration Pattern

CloudTrail operates independently of the application. It
captures events at the AWS account level, not the application
level. The RDS audit_logs table captures application-level
changes to GRC data, while CloudTrail captures infrastructure-
level changes to AWS resources. Together they provide a
complete audit picture at both layers.

### Performance Considerations

CloudTrail has no impact on the performance of other services.
Log delivery to S3 happens asynchronously and introduces no
latency to the operations being logged.

### Cost Considerations

One trail delivering management events to S3 is free.
Additional trails, data events (such as logging every S3
object-level operation) and CloudTrail Insights incur
additional charges. For this project, the single trail
covering management events is sufficient and costs nothing.

-----

## AWS Config

### What It Does in This Platform

AWS Config was intended to serve as the continuous compliance
monitoring service, evaluating AWS resources against defined
rules and triggering the Lambda function when compliance
changes are detected.

The Config recorder was set up during deployment, but the
delivery channel could not be configured because the LabRole
does not have the config:PutDeliveryChannel permission. This
is a known limitation of the AWS Academy Learner Lab sandbox
environment.

In a standard AWS account with a properly scoped IAM role,
Config would deliver evaluation results to an S3 bucket and
SNS topic, and would trigger the compliance monitor Lambda
automatically on any resource configuration change.

### Integration Pattern

In the intended full deployment, Config evaluates resources
against rules mapped to the six compliance frameworks.
Non-compliant evaluations trigger an EventBridge rule that
invokes the Lambda compliance monitor, which scores the risk
and updates DynamoDB and RDS.

### Cost Considerations

AWS Config charges per configuration item recorded and per
active rule evaluation. Costs scale with the number of
resources being monitored. For this project scale, Config
costs would be minimal in a full deployment.

-----

## Amazon CloudWatch

### What It Does in This Platform

CloudWatch monitors metrics from Lambda, RDS and the
application layer. Alarms are configured to notify the team
when the compliance risk score exceeds the alert threshold
of 7.0.

### Integration Pattern

When the compliance monitor Lambda calculates a risk score,
it publishes a custom metric to CloudWatch. If that metric
crosses the defined threshold, the CloudWatch alarm transitions
to ALARM state and triggers an SNS notification. This creates
an automated alert path that does not require anyone to
manually check the dashboard.

### Performance Considerations

CloudWatch metric collection and alarm evaluation happen
asynchronously and have no impact on application performance.

### Cost Considerations

CloudWatch charges for custom metrics, API requests, dashboard
usage and alarm evaluations. The AWS Free Tier includes 10
custom metrics, 10 alarms and 1 million API requests per month.
For this platform at development scale, CloudWatch costs fall
within the Free Tier.

-----

## Amazon SNS

### What It Does in This Platform

SNS sends alert notifications when the compliance risk score
exceeds 7.0. Notifications can be delivered by email or SMS
to subscribed endpoints.

### Integration Pattern

CloudWatch triggers the SNS topic when an alarm condition is
met. The Lambda compliance monitor can also publish directly
to the SNS topic for immediate alerts without waiting for the
CloudWatch alarm evaluation cycle.

### Cost Considerations

SNS charges per notification published and per delivery.
Email notifications are free. SMS notifications incur a small
per-message charge that varies by destination country. For a
development platform sending occasional alerts, SNS costs are
negligible.

-----

## AWS KMS

### What It Does in This Platform

Two KMS keys were created by the database CloudFormation stack:

- One key encrypts the RDS database at rest
- One key encrypts both S3 buckets at rest

KMS key rotation is configured so the encryption key material
changes automatically over time without any manual intervention.

### Integration Pattern

RDS, S3 and DynamoDB reference the KMS key ARNs in their
resource configurations. Encryption and decryption happen
transparently when services read and write data. Applications
and Lambda functions do not need to handle encryption
themselves.

### Cost Considerations

KMS charges per key per month and per API call. Each customer-
managed key costs a small flat monthly fee. For two keys at
this scale, the cost is minimal. AWS-managed keys (used by
default for some services) are free, but customer-managed keys
provide more control over rotation and access policies.

-----

## AWS IAM

### What It Does in This Platform

IAM controls which services and users can perform which actions
in the AWS account. All Lambda functions and CloudFormation
stacks in this project use the LabRole
(arn:aws:iam::975049998247:role/LabRole), which is the only
IAM role available in the AWS Academy Learner Lab environment.

In a standard AWS account, each service would have its own
dedicated IAM role with only the permissions it needs. For
example, the compliance monitor Lambda would have a role that
allows it to write to DynamoDB and RDS but nothing else.

### Integration Pattern

IAM roles are attached to Lambda functions at creation time.
CloudFormation uses the LabRole to create and manage all
resources. No IAM access keys are created or stored anywhere
in this project.

### Cost Considerations

IAM has no cost. Creating and managing roles, policies and
users is free regardless of scale.
