# Best Practices

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

## AWS Best Practices

### Use Infrastructure as Code for Everything

Every resource in this platform was defined in CloudFormation
templates rather than created manually through the AWS Console.
This means the entire infrastructure can be deleted and redeployed
from scratch with a single command, and every configuration
decision is documented in version-controlled files.

When the database stack failed five times during deployment, the
fix was made to the template file itself, not patched around.
That discipline meant the final deployed state matched exactly
what was in the code.

Always commit your CloudFormation templates to version control
before deploying. If a stack fails, the error is in the template.
Fix it there, not in the console.

### Check Available Service Versions Before Deploying

The database stack originally specified MySQL version 8.0.35.
This version is not available in the AWS Academy Learner Lab
environment, which caused repeated deployment failures. Before
hardcoding any service version into a CloudFormation template,
verify what is actually available in your target environment:

```bash
aws rds describe-db-engine-versions \
  --engine mysql \
  --query 'DBEngineVersions[*].EngineVersion'
```

This applies to any versioned service, including Lambda runtimes, RDS
engine versions, ECS task definition revisions. Never assume a
version is available until you have confirmed it.

### Use the Right Tool for Each Job

This platform uses three different storage services because each
one serves a different purpose:

- **RDS MySQL** handles structured relational data, including frameworks,
  controls, risks, assets and audit logs. These have relationships
  between them that require a relational database.
- **DynamoDB** handles real-time compliance status. It is faster
  than querying RDS for data that changes frequently and needs to
  be read instantly by the dashboard.
- **S3** handles evidence documents and audit logs. Object storage
  is the right choice for files that need long-term retention,
  versioning and cheap retrieval.

Using DynamoDB for everything or RDS for everything would have
been the wrong approach. Match the storage service to the data
type and access pattern.

### Design for Private Networking from the Start

RDS and Lambda are deployed in private subnets with no direct
internet access. The NAT Gateway handles any outbound calls they
need to make. This design decision meant that when it came time
to load data into RDS from CloudShell, direct access was blocked,
which is exactly what private subnet design is supposed to do.

The solution was to create a VPC-connected Lambda function that
runs inside the private network. This is the production-correct
approach. Designing for private networking from the start forced
a better solution than if access had been left open.

### Always Verify After Deploying

After each phase, run a verification command before moving on.
Do not assume a deployment succeeded because no error appeared:

```bash
# Confirm stack status
aws cloudformation describe-stacks \
  --stack-name grc-database-stack \
  --query 'Stacks[0].StackStatus'

# Confirm RDS is available
aws rds describe-db-instances \
  --query 'DBInstances[0].DBInstanceStatus'

# Confirm Lambda is active
aws lambda get-function \
  --function-name grc-compliance-monitor \
  --query 'Configuration.State'

# Confirm CloudTrail is logging
aws cloudtrail get-trail-status \
  --name grc-audit-trail \
  --query 'IsLogging'
```

Each command should return the expected value before the next
phase begins. Catching a problem at the verification step is
much faster than discovering it three phases later.

-----

## Security Best Practices

### Never Store Credentials in Code

No passwords, access keys or connection strings appear anywhere
in this codebase. The database password is passed as a
CloudFormation parameter at deployment time and never written
into a file that gets committed to GitHub.

Lambda functions connect to RDS using the endpoint and
credentials passed through environment variables, not hardcoded
strings. Before pushing anything to a public repository,
confirm that no credentials are present in any file.

### Use IAM Roles Instead of Access Keys

Every service in this platform authenticates through IAM roles.
Lambda assumes the LabRole to interact with DynamoDB, RDS and
S3. No access keys are created, stored or rotated. This removes
an entire category of credential exposure risk.

In a production environment outside the Learner Lab, create a
dedicated IAM role for each service with only the permissions
that service actually needs. The LabRole was used here because
it is the only role available in the sandbox environment.

### Encrypt Everything at Rest

All three storage services in this platform are encrypted:

- RDS uses a KMS key created by the database CloudFormation stack
- Both S3 buckets have server-side encryption enabled using KMS
- DynamoDB tables are encrypted at rest by default

Encryption at rest means that if the underlying storage were
ever accessed directly, the data would be unreadable without
the KMS key. KMS key rotation is configured so the encryption
key changes automatically over time.

### Enforce Least Privilege Through Security Groups

The RDS security group (sg-0e9455394d5b6c9f3) allows inbound
traffic on port 3306 only from the ECS security group
(sg-0e63951b8ee7375cd). Nothing else can reach the database:
not the internet, not CloudShell, not any other service.

This is the principle of least privilege applied at the network
level. Each security group rule should only allow the minimum
access required for the specific service that needs it.

### Enable and Verify Audit Logging

The CloudTrail audit trail (grc-audit-trail) was created and
verified to be logging before the deployment was considered
complete. Every API call made in the account is now recorded
in the S3 compliance reports bucket.

Enabling logging is not enough. Always verify it is actually
working:

```bash
aws cloudtrail get-trail-status \
  --name grc-audit-trail \
  --query 'IsLogging'
```

An audit trail that is created but not started provides no
protection. Verification should be part of every deployment
checklist.

### Enable S3 Versioning for Evidence Integrity

Both S3 buckets in this platform have versioning enabled. This
means that every upload creates a new version rather than
overwriting the previous one. Evidence documents cannot be
accidentally or intentionally deleted without leaving a trace.

For compliance purposes, the ability to prove that a document
has not been modified since it was stored is as important as
the document itself. Versioning provides that guarantee.

-----

## Compliance Best Practices

### Map Controls to Frameworks at the Data Level

The controls table in the grcdb database has a `framework_id`
foreign key that links each control directly to its parent
framework. This means a single SQL query can retrieve all
controls for any given framework, or identify which controls
satisfy requirements across multiple frameworks at once.

Hard-coding framework relationships in application logic instead
of the database would have made the platform rigid. Storing
them in the data model keeps the platform flexible as new
frameworks are added.

### Automate Compliance Checking, Not Schedule It

AWS Config checks compliance continuously, not on a schedule.
The moment a resource configuration changes, Config evaluates
it against the defined rules and the Lambda function calculates
an updated risk score. There is no waiting for the next
scheduled scan to discover a problem.

Scheduled compliance checks are a legacy pattern. In a cloud
environment where resources can be created, modified and deleted
in seconds, continuous monitoring is the only approach that
provides real visibility.

### Document Limitations Honestly

The AWS Config delivery channel could not be configured in the
Learner Lab environment because the LabRole lacks the required
permissions. This limitation is documented clearly in this
repository rather than hidden or worked around with a misleading
alternative.

In a real compliance context, undocumented gaps are a liability.
A documented gap with a compensating control (CloudTrail in
this case) is a defensible position. Always document what you
could not implement and explain what you did instead.

### Maintain a Complete Audit Trail at Every Layer

This platform captures audit events at three separate levels:

- **CloudTrail** records every AWS API call at the account level
- **RDS audit_logs table** records every change to GRC data
  including who made the change and when
- **S3 versioning** preserves every version of every evidence
  document uploaded to the buckets

This layered approach means that even if one logging mechanism
were compromised or unavailable, the other two would still
provide a complete record. A single audit log is a single point
of failure.

### Set Retention Policies and Enforce Them

Log retention is configured to a minimum of 30 days across all
logging mechanisms. In a production environment, compliance
frameworks like ISO 27001 and PCI DSS specify minimum retention
periods that are often longer. ISO 27001 typically requires
one year for audit logs.

Set retention policies when deploying, not as an afterthought.
Logs that were never retained cannot be produced during an audit.

-----

## Operational Best Practices

### Read Error Messages Before Taking Action

When the database CloudFormation stack failed, the instinct
might be to delete and redeploy immediately. Instead, the
correct approach is to read the stack events first:

```bash
aws cloudformation describe-stack-events \
  --stack-name grc-database-stack \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`].[LogicalResourceId,ResourceStatusReason]' \
  --output table
```

This command showed exactly which resource failed and why:
the S3 BucketEncryption indentation first, then the MySQL
version. Deleting and redeploying without reading the error
would have repeated the same failure.

Always read the error before you fix it. The error message is
the fastest path to the solution.

### Never Redeploy a Phase That Already Completed

CloudFormation stacks that reach CREATE_COMPLETE should not be
redeployed unless there is a specific change to make. Attempting
to create a stack that already exists will fail with an
`AlreadyExistsException`.

If you need to change a deployed stack, use `update-stack`
rather than deleting and recreating it. If you must start fresh,
delete the stack first and wait for the deletion to complete
before redeploying.

### Automate Testing and Run It Every Time

The test suite covers 22 test cases across 6 categories. It
takes 0.001 seconds to run. There is no reason not to run it
after every significant change to the platform:

```bash
python3 test_cases.py
```

Tests catch problems that manual verification misses. A
compliance platform that cannot pass its own test suite should
not be considered deployed. Run the tests, check the result,
and investigate any failure before moving on.

### Package Dependencies With Your Functions

Lambda functions do not have access to libraries that are not
included in the deployment package. The `pymysql` library
must be zipped together with the function code before deploying.
This is not optional. A Lambda function that imports pymysql
without packaging it will crash immediately on invocation.

Keep a record of every external dependency your functions
require. Before deploying, confirm that all dependencies are
present in the zip file and that their versions are compatible
with the Lambda Python runtime you are targeting.

### Know the Boundaries of Your Environment

The AWS Academy Learner Lab imposes restrictions that do not
exist in a standard AWS account. Knowing these boundaries early
prevents wasted time trying to fix something that is not broken:

- AWS Config delivery channel creation requires permissions the
  LabRole does not have
- RDS cannot be reached directly from CloudShell due to VPC
  private subnet placement
- Learner Lab sessions expire and must be restarted. Always
  check that credentials are still active before running commands

Understanding your environment is as important as understanding
your architecture. Work within the constraints, document them
clearly, and move forward.
