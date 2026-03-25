# Architecture Design

## GRC208 Capstone: AWS Integrated GRC Platform

**Student:** Emmanuella Ebubechukwu
**Student ID:** 2025/GRC/10041
**Deployed:** March 24, 2026
**Environment:** AWS Academy Learner Lab
**Region:** us-east-1

-----

## System Architecture

The AWS Integrated GRC Platform is built as a cloud-native
application on Amazon Web Services. All resources run within
a single AWS account (975049998247) in the us-east-1 region.

The architecture follows a layered design with three distinct
tiers: a network layer, an application layer and a data layer.
Each tier has clearly defined boundaries and each service
within it has a specific role.

### Network Layer

The foundation of the platform is a Virtual Private Cloud
(vpc-0d9aae45de7e2ace7) with the CIDR block 10.0.0.0/16.
The VPC is divided into public and private subnets spread
across two availability zones for redundancy.

**Public subnets** host resources that need to accept inbound
traffic from the internet:

- Application Load Balancer receives user traffic and routes
  it to the application running on ECS Fargate
- NAT Gateway provides outbound internet access for resources
  in the private subnets without exposing them to inbound
  connections

**Private subnets** (subnet-0a1b4a431b6ea9a47 and
subnet-0cebfce803eaa150a) host all compute and data resources:

- ECS Fargate runs the containerized GRC web application
- RDS MySQL hosts the primary relational database
- Lambda functions handle compliance monitoring and data loading

Nothing in the private subnets is reachable from outside the
VPC. This is intentional and by design.

### Application Layer

The application layer consists of two components:

**ECS Fargate** runs the React-based GRC dashboard as a
containerized application. Fargate was chosen because it
removes the need to manage EC2 instances while still providing
the control and flexibility of containers.

**AWS Lambda** handles event-driven automation. The
grc-compliance-monitor function runs when AWS Config detects
a compliance change, calculates the updated risk score and
writes the result to both DynamoDB and RDS. A second function,
grc-db-loader, handles database population from inside the VPC.

### Data Layer

The data layer uses three storage services, each chosen for
a specific purpose:

**Amazon RDS MySQL 8.0.40** stores all structured relational
GRC data. The six tables (frameworks, controls, risks, assets,
compliance_status, audit_logs) have foreign key relationships
that require a relational database. The instance identifier is
grc-capstone-db and it is accessible only from within the VPC.

**Amazon DynamoDB** stores real-time compliance status across
three tables: grc-compliance-status, grc-controls and
grc-risk-register. These tables serve the dashboard with fast
reads for data that changes frequently.

**Amazon S3** stores compliance evidence and audit logs across
two buckets: grc-capstone-evidence-bucket-975049998247 and
grc-capstone-compliance-reports-975049998247. Both buckets
have versioning and KMS encryption enabled.

### Supporting Services

**CloudTrail** (grc-audit-trail) records every API call in
the account and delivers logs to the compliance reports S3
bucket. It provides the infrastructure-level audit trail that
complements the application-level audit_logs table in RDS.

**AWS Config** was configured to monitor resource compliance
against rules mapped to the six supported frameworks. The
delivery channel could not be fully activated in the Learner
Lab due to LabRole permission restrictions. CloudTrail serves
as the compensating control.

**CloudWatch** monitors metrics from Lambda and the
application layer. Alarms are set to trigger SNS notifications
when the risk score crosses 7.0.

**SNS** sends alert notifications by email or SMS when
CloudWatch alarm conditions are met.

**KMS** provides two customer-managed encryption keys: one
for RDS and one for S3. Both keys have rotation enabled.

-----

## Design Decisions

### Why Private Subnets for RDS and Lambda

Placing RDS in a private subnet means the database has no
direct internet exposure. This is a fundamental security
decision. The trade-off is that loading data into RDS from
outside the VPC requires an indirect approach.

During deployment, this decision was validated when CloudShell
could not connect to RDS directly. The solution was to create
grc-db-loader, a VPC-connected Lambda function that runs
inside the private network. This is the production-correct
approach and led to a more realistic architecture than if
direct access had been left open.

### Why Lambda for Compliance Monitoring Instead of ECS

The compliance monitor runs in response to events, not
continuously. When AWS Config detects a change, it triggers
the function. When nothing changes, the function is not
running. Lambda is the right choice for event-driven workloads
because it scales to zero when idle and scales instantly when
triggered. Running a continuously active ECS service for this
workload would consume resources and cost money even when
nothing was happening.

### Why DynamoDB Alongside RDS

RDS is the system of record. Every compliance snapshot, risk
score change and audit event is written to RDS for historical
analysis and reporting. However, querying RDS every time a
user loads the dashboard introduces unnecessary latency for
data that does not require complex relational queries.

DynamoDB serves the live dashboard view. It holds only the
current state and is optimized for fast single-item reads.
The compliance monitor writes to both stores simultaneously
so the dashboard always reflects the latest state without
hitting RDS.

### Why CloudFormation for Infrastructure Provisioning

All infrastructure in this project is defined in two
CloudFormation YAML templates. The decision to use
Infrastructure as Code from the start meant that when the
database stack failed five times due to template errors,
fixing the template and redeploying was straightforward.
Each fix was committed to version control before redeploying
so the template always reflected the actual deployed state.

Manual console deployments cannot be reproduced reliably.
CloudFormation templates can be redeployed to any AWS account
in any region with a single command.

### Why Three Separate Compliance Frameworks Were Not Used

ISO 27001, NIST CSF, PCI DSS, HIPAA, GDPR and SOC 2 were
all loaded into the same database rather than maintaining
separate environments for each. The frameworks table links
controls to their parent framework, which means a single
query can identify all controls for a given framework or
all frameworks that a given control satisfies. This shared
data model is more efficient and reflects how real GRC
platforms handle multi-framework compliance.

-----

## Technology Stack

### Infrastructure

|Tool              |Purpose                                 |
|------------------|----------------------------------------|
|AWS CloudFormation|Infrastructure as Code for all resources|
|Amazon VPC        |Network isolation and segmentation      |
|AWS IAM (LabRole) |Access control for all services         |
|AWS KMS           |Encryption key management               |

### Compute and Storage

|Service                |Purpose                               |
|-----------------------|--------------------------------------|
|AWS Lambda (Python 3.9)|Event-driven compliance monitoring    |
|Amazon ECS Fargate     |Containerized GRC web application     |
|Amazon RDS MySQL 8.0.40|Primary relational database (grcdb)   |
|Amazon S3              |Evidence and compliance report storage|
|Amazon DynamoDB        |Real-time compliance status           |

### Monitoring and Compliance

|Service          |Purpose                        |
|-----------------|-------------------------------|
|AWS Config       |Resource compliance evaluation |
|AWS CloudTrail   |Account-level API audit logging|
|Amazon CloudWatch|Metrics, alarms and monitoring |
|Amazon SNS       |Alert notifications            |
|AWS Security Hub |Aggregated security findings   |

### Application

|Component  |Purpose                      |
|-----------|-----------------------------|
|Python     |Lambda function code         |
|React + CSS|GRC dashboard frontend       |
|pymysql    |MySQL connectivity for Lambda|
|MySQL      |Relational database engine   |

-----

## Deployment Strategy

The platform is deployed in five sequential phases. Each
phase depends on the previous one completing successfully
before the next begins.

### Phase 1: Network Infrastructure

The network stack (grc-network-stack) is deployed first
using cloudformation-network-stack.yaml. This creates the
VPC, subnets, gateways and security groups that all other
resources depend on. All subsequent CloudFormation stacks
reference the outputs of this stack for subnet IDs and
security group IDs.

This stack was pre-deployed and verified at CREATE_COMPLETE
before deployment began.

### Phase 2: Database Infrastructure

The database stack (grc-database-stack) is deployed second
using cloudformation-database-stack.yaml. This creates RDS,
S3, DynamoDB and KMS resources inside the VPC established
in Phase 1.

Two template errors were identified and fixed before this
stack deployed successfully:

- A YAML indentation error in the S3 BucketEncryption block
- An unavailable MySQL version (8.0.35 updated to 8.0.40)

The stack takes approximately 15 minutes to reach
CREATE_COMPLETE due to RDS provisioning time.

### Phase 3: Lambda Deployment

The compliance monitor Lambda function is deployed after the
database stack completes. The function is packaged with
pymysql before deployment because this library is not
included in the default Lambda Python runtime. The function
is configured with VPC access to reach the private RDS
instance.

### Phase 4: Monitoring and Audit Logging

CloudTrail is configured after the S3 bucket is available
from Phase 2. A bucket policy is applied first to authorize
CloudTrail log delivery, then the trail is created and
logging is started. Logging status is verified before
marking this phase complete.

### Phase 5: Data Loading

Sample data is loaded into RDS using the grc-db-loader
Lambda function. This function was created specifically for
this purpose because RDS is in a private subnet and cannot
be reached from CloudShell directly. The function connects
to RDS from inside the VPC and creates four tables with
sample data covering frameworks, controls, risks and
audit logs.

### Verification

After all five phases complete, the following commands
confirm the full deployment is in place:

```bash
aws cloudformation describe-stacks \
  --query 'Stacks[*].[StackName,StackStatus]' \
  --output table

aws dynamodb list-tables

aws rds describe-db-instances \
  --query 'DBInstances[0].DBInstanceStatus'

aws cloudtrail get-trail-status \
  --name grc-audit-trail \
  --query 'IsLogging'

python3 test_cases.py
```

All five commands should return expected values and all 22
tests should pass before the deployment is considered
complete.
