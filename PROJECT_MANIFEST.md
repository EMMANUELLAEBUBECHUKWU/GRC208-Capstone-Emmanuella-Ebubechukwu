# Project Manifest

## GRC208 Capstone: AWS Integrated GRC Platform

**Student:** Emmanuella Ebubechukwu
**Student ID:** 2025/GRC/10041
**Deployed:** March 24, 2026
**Environment:** AWS Academy Learner Lab
**Region:** us-east-1
**Total Files:** 17
**Total Lines of Code:** 5,602

-----

## Complete File Listing

|File                              |Type          |Size       |Purpose                                 |
|----------------------------------|--------------|-----------|----------------------------------------|
|README.md                         |Documentation |-          |Project overview and quick start        |
|DEPLOYMENT_GUIDE.md               |Documentation |-          |Step-by-step deployment instructions    |
|BEST_PRACTICES.md                 |Documentation |-          |AWS, security and compliance guidance   |
|AWS_SERVICES_GUIDE.md             |Documentation |-          |Detailed service explanations           |
|architecture_design.md            |Documentation |-          |System architecture and design decisions|
|PROJECT_MANIFEST.md               |Documentation |-          |This file                               |
|DELIVERY_SUMMARY.md               |Documentation |-          |Submission checklist                    |
|cloudformation-network-stack.yaml |Infrastructure|-          |VPC and networking resources            |
|cloudformation-database-stack.yaml|Infrastructure|-          |RDS, S3, DynamoDB and KMS resources     |
|lambda_compliance_monitor.py      |Code          |350+ lines |Compliance monitoring Lambda function   |
|grc-dashboard.jsx                 |Code          |400+ lines |React frontend dashboard                |
|grc-dashboard.css                 |Code          |500+ lines |Dashboard styling                       |
|test_cases.py                     |Code          |22 tests   |Automated test suite                    |
|sample_data.sql                   |Data          |50+ records|SQL for loading GRC sample data         |
|load_sql.py                       |Code          |-          |VPC Lambda data loader                  |
|deploy.sh                         |Config        |-          |Deployment automation script            |
|response.json                     |Config        |-          |Lambda invocation response output       |

-----

## File Purposes

### Documentation Files

**README.md**
The entry point for anyone opening this repository. It explains
what the platform does, how to access AWS through the Learner
Lab, and what each phase of deployment covers. Four AWS access
options are documented here including the AWS Academy Learner
Lab route used for this submission.

**DEPLOYMENT_GUIDE.md**
The step-by-step guide covering all five deployment phases with
exact commands, expected outputs and troubleshooting steps for
every error encountered during the actual deployment on March
24, 2026. This was the primary reference document used
throughout the deployment session.

**BEST_PRACTICES.md**
Covers AWS, security, compliance and operational best practices
applied in this project. Each practice is grounded in a real
decision or problem encountered during deployment, not
extracted from generic documentation.

**AWS_SERVICES_GUIDE.md**
Explains every AWS service used in the platform including what
it does, how it integrates with the other services, performance
considerations and cost optimization guidance. References real
resource names and IDs from the actual deployment.

**architecture_design.md**
Documents the system architecture, explains the design
decisions behind key choices such as private subnet placement,
Lambda vs ECS for compliance monitoring, and DynamoDB alongside
RDS, and walks through the five-phase deployment strategy.

**PROJECT_MANIFEST.md**
This file. Provides a complete inventory of all 17 project
files, their purposes, how they relate to each other and the
workflow followed during development and deployment.

**DELIVERY_SUMMARY.md**
The submission checklist confirming all deliverables are
complete and listing what was achieved during the deployment
session on March 24, 2026.

-----

### Infrastructure Files

**cloudformation-network-stack.yaml**
Defines the entire network layer of the platform. Creates the
VPC (vpc-0d9aae45de7e2ace7), four subnets across two
availability zones, an Internet Gateway, a NAT Gateway, route
tables and four security groups. This stack must reach
CREATE_COMPLETE before the database stack is deployed.

Deployed as: grc-network-stack
Status: CREATE_COMPLETE (pre-deployed)

**cloudformation-database-stack.yaml**
Defines the data layer of the platform. Creates the RDS MySQL
instance, two S3 buckets, three DynamoDB tables and two KMS
encryption keys. This file was modified from its original
version to fix two errors before successful deployment:

- S3 BucketEncryption YAML indentation corrected
- MySQL EngineVersion changed from 8.0.35 to 8.0.40

Deployed as: grc-database-stack
Status: CREATE_COMPLETE

-----

### Application Code Files

**lambda_compliance_monitor.py**
The main compliance monitoring Lambda function. It is triggered
by AWS Config when a resource compliance change is detected.
It retrieves the compliance evaluation results, calculates the
risk score using the Probability x Impact formula, stores the
result in both DynamoDB and RDS, and publishes an SNS alert
if the score exceeds 7.0.

Deployed as: grc-compliance-monitor
Runtime: Python 3.9
VPC: Yes (private subnets)
Dependencies: pymysql (packaged with function)

**grc-dashboard.jsx**
The React frontend component for the GRC dashboard. Displays
real-time compliance status, risk scores, control status and
framework coverage pulled from DynamoDB. Built as a single-page
application that connects to the backend API running on ECS
Fargate.

**grc-dashboard.css**
The stylesheet for the GRC dashboard. Controls layout,
typography, color scheme and responsive behavior of all
dashboard components.

**test_cases.py**
The automated test suite covering 22 test cases across six
categories: compliance monitoring, risk assessment, data
validation, database operations, audit logging and integration
tests. All 22 tests pass in 0.001 seconds.

Run with:

```bash
python3 test_cases.py
```

**load_sql.py**
A utility Lambda function created during deployment to solve
the problem of loading data into RDS from outside the VPC.
Because RDS is in a private subnet, CloudShell cannot connect
to it directly. This function runs inside the VPC and executes
the SQL statements to create tables and load sample data.

Deployed as: grc-db-loader
Runtime: Python 3.9
VPC: Yes (same private subnets as compliance monitor)
Dependencies: pymysql (packaged with function)

-----

### Data and Configuration Files

**sample_data.sql**
Contains the SQL statements for creating and populating all
six database tables with sample GRC data. Includes:

- 6 compliance frameworks (ISO 27001, NIST CSF, PCI DSS,
  HIPAA, GDPR, SOC 2)
- 10 sample controls linked to frameworks
- 6 sample risks with probability, impact and scoring
- 5 initial audit log entries
- Asset definitions and compliance status snapshots

**deploy.sh**
A shell script that automates the deployment sequence. Runs
the CloudFormation deployments, Lambda packaging and
deployment steps in the correct order. Used as a reference
for the manual deployment steps documented in
DEPLOYMENT_GUIDE.md.

**response.json**
The JSON response file generated when the grc-db-loader
Lambda function was invoked to load sample data. Contains
the statusCode 200 response confirming successful data
loading and listing the four tables created.

-----

## File Relationships

The files in this project fall into four dependency groups:

**Infrastructure depends on nothing**
cloudformation-network-stack.yaml and
cloudformation-database-stack.yaml are self-contained. The
database stack references outputs from the network stack,
but neither depends on any application code file.

**Application code depends on infrastructure**
lambda_compliance_monitor.py, load_sql.py and the dashboard
files all depend on the infrastructure being deployed first.
The Lambda functions need the VPC, subnets and RDS endpoint
to exist before they can run.

**Data depends on infrastructure and code**
sample_data.sql depends on the RDS database being live.
load_sql.py reads and executes sample_data.sql to populate
the database. response.json is the output of that process.

**Tests depend on data**
test_cases.py validates the platform behavior including data
structure and compliance calculations. The tests are designed
to pass after sample_data.sql has been loaded. Running the
tests before loading data will result in failures.

**Documentation depends on everything**
The documentation files (README.md, DEPLOYMENT_GUIDE.md and
the rest) were written after the deployment was complete.
They reflect the actual deployed state, the real resource
IDs and the genuine challenges encountered along the way.

-----

## Development Workflow

The project was built and deployed in the following sequence
on March 24, 2026:

**1. Repository Setup**
The repository was cloned from GitHub into AWS CloudShell
using a Personal Access Token for authentication. All 17
files were confirmed present before deployment began.

**2. Network Verification**
The network stack was verified as CREATE_COMPLETE before
any other deployment step. The subnet IDs and security
group IDs from its outputs were used in all subsequent
steps.

**3. Template Debugging and Database Deployment**
The database stack template was debugged through five
failed attempts. Each failure was diagnosed using
describe-stack-events before the fix was applied to the
template. The two root causes (YAML indentation and MySQL
version) were fixed and the stack deployed successfully
on the sixth attempt.

**4. Lambda Packaging and Deployment**
The compliance monitor Lambda was packaged with pymysql
using pip install -t, zipped with the function code and
deployed with VPC configuration pointing to the private
subnets.

**5. CloudTrail Configuration**
The S3 bucket policy was applied first to authorize
CloudTrail log delivery. The trail was then created and
started, and logging was verified active before continuing.

**6. Data Loading**
The grc-db-loader Lambda was created specifically to solve
the private subnet access problem. It was packaged and
deployed with VPC configuration, then invoked to create
tables and load all sample data into RDS.

**7. Testing**
The full test suite was run after data loading was
confirmed. All 22 tests passed in 0.001 seconds.

**8. Documentation**
All documentation files were written after deployment was
complete so they reflect the actual deployed state rather
than a planned or theoretical one.
