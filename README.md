# GRC208 Capstone Project - AWS Integrated GRC Platform

## Student Information
- **Name:** Emmanuella Ebubechukwu
- **Student ID:** 2025/GRC/10041
- **Course:** GRC208 - Governance, Risk, and Compliance
- **Institution:** International Cybersecurity and Digital Forensics Academy (ICDFA)
- **Date Deployed:** March 24, 2026

## Project Summary
This capstone project demonstrates the deployment of an enterprise-grade AWS Integrated GRC Platform with compliance monitoring, risk assessment, and audit logging.

## Deployment Status
- Phase 1: Network Stack - CREATE_COMPLETE
- Phase 2: Database Stack - CREATE_COMPLETE
- Phase 3: Lambda Function - Deployed Successfully
- Phase 4: CloudTrail Audit Logging - Active
- Phase 5: Sample Data Loaded - 4 Tables Created
- Tests: 22/22 Passing

## AWS Resources Deployed
- VPC with public and private subnets
- RDS MySQL 8.0.40 database
- AWS Lambda compliance monitor
- S3 evidence and compliance reports buckets
- DynamoDB tables (3)
- KMS encryption keys
- CloudTrail audit trail

## Files
- cloudformation-network-stack.yaml - Network infrastructure
- cloudformation-database-stack.yaml - Database infrastructure
- lambda_compliance_monitor.py - Compliance monitoring function
- load_sql.py - Database data loading script
- test_cases.py - 22 automated tests
- sample_data.sql - Sample GRC data
- grc-dashboard.jsx - React dashboard
- grc-dashboard.css - Dashboard styling
- deploy.sh - Deployment automation script
