"""
AWS GRC Platform - Compliance Monitoring Lambda Function
This function monitors AWS Config compliance status and generates compliance reports
"""

import json
import boto3
import logging
from datetime import datetime
from typing import Dict, List, Any

# Initialize AWS clients
config_client = boto3.client('config')
s3_client = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
sns_client = boto3.client('sns')

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Environment variables
COMPLIANCE_TABLE = 'grc-compliance-status'
ALERT_SNS_TOPIC = 'arn:aws:sns:us-east-1:ACCOUNT_ID:grc-compliance-alerts'
EVIDENCE_BUCKET = 'grc-evidence-bucket'


class ComplianceMonitor:
    """Monitor AWS resource compliance status"""
    
    def __init__(self):
        self.table = dynamodb.Table(COMPLIANCE_TABLE)
        self.compliance_data = []
        self.non_compliant_resources = []
    
    def get_config_compliance_status(self) -> Dict[str, Any]:
        """Retrieve compliance status from AWS Config"""
        try:
            response = config_client.describe_compliance_by_config_rule()
            return response
        except Exception as e:
            logger.error(f"Error retrieving Config compliance: {str(e)}")
            raise
    
    def get_non_compliant_resources(self, rule_name: str) -> List[Dict]:
        """Get non-compliant resources for a specific rule"""
        try:
            response = config_client.get_compliance_details_by_config_rule(
                ConfigRuleName=rule_name,
                ComplianceTypes=['NON_COMPLIANT']
            )
            return response.get('EvaluationResults', [])
        except Exception as e:
            logger.error(f"Error retrieving non-compliant resources: {str(e)}")
            return []
    
    def analyze_compliance(self) -> Dict[str, Any]:
        """Analyze overall compliance status"""
        compliance_status = self.get_config_compliance_status()
        rules = compliance_status.get('ComplianceByConfigRules', [])
        
        total_rules = len(rules)
        compliant_rules = sum(1 for rule in rules if rule['Compliance']['ComplianceType'] == 'COMPLIANT')
        non_compliant_rules = total_rules - compliant_rules
        
        compliance_percentage = (compliant_rules / total_rules * 100) if total_rules > 0 else 0
        
        return {
            'total_rules': total_rules,
            'compliant_rules': compliant_rules,
            'non_compliant_rules': non_compliant_rules,
            'compliance_percentage': round(compliance_percentage, 2),
            'timestamp': datetime.utcnow().isoformat(),
            'rules': rules
        }
    
    def store_compliance_snapshot(self, compliance_data: Dict[str, Any]) -> bool:
        """Store compliance snapshot in DynamoDB"""
        try:
            self.table.put_item(
                Item={
                    'timestamp': compliance_data['timestamp'],
                    'compliance_percentage': compliance_data['compliance_percentage'],
                    'total_rules': compliance_data['total_rules'],
                    'compliant_rules': compliance_data['compliant_rules'],
                    'non_compliant_rules': compliance_data['non_compliant_rules'],
                    'rules_detail': json.dumps(compliance_data['rules']),
                    'ttl': int(datetime.utcnow().timestamp()) + (90 * 24 * 60 * 60)  # 90 days
                }
            )
            logger.info("Compliance snapshot stored successfully")
            return True
        except Exception as e:
            logger.error(f"Error storing compliance snapshot: {str(e)}")
            return False
    
    def generate_compliance_report(self, compliance_data: Dict[str, Any]) -> str:
        """Generate compliance report"""
        report = f"""
GRC COMPLIANCE MONITORING REPORT
Generated: {compliance_data['timestamp']}

COMPLIANCE SUMMARY
==================
Total Rules: {compliance_data['total_rules']}
Compliant Rules: {compliance_data['compliant_rules']}
Non-Compliant Rules: {compliance_data['non_compliant_rules']}
Compliance Percentage: {compliance_data['compliance_percentage']}%

COMPLIANCE STATUS BY RULE
=========================
"""
        for rule in compliance_data['rules']:
            rule_name = rule['ConfigRuleName']
            compliance_type = rule['Compliance']['ComplianceType']
            report += f"\n- {rule_name}: {compliance_type}"
        
        return report
    
    def send_alert_if_non_compliant(self, compliance_data: Dict[str, Any]) -> None:
        """Send SNS alert if non-compliant resources detected"""
        if compliance_data['non_compliant_rules'] > 0:
            message = f"""
COMPLIANCE ALERT: Non-Compliant Resources Detected

Compliance Percentage: {compliance_data['compliance_percentage']}%
Non-Compliant Rules: {compliance_data['non_compliant_rules']}

Please review the GRC dashboard for details.
"""
            try:
                sns_client.publish(
                    TopicArn=ALERT_SNS_TOPIC,
                    Subject='GRC Compliance Alert - Non-Compliant Resources',
                    Message=message
                )
                logger.info("Compliance alert sent")
            except Exception as e:
                logger.error(f"Error sending alert: {str(e)}")
    
    def save_report_to_s3(self, report: str, timestamp: str) -> bool:
        """Save compliance report to S3"""
        try:
            key = f"compliance-reports/{timestamp.replace(':', '-')}-compliance-report.txt"
            s3_client.put_object(
                Bucket=EVIDENCE_BUCKET,
                Key=key,
                Body=report,
                ContentType='text/plain'
            )
            logger.info(f"Report saved to S3: {key}")
            return True
        except Exception as e:
            logger.error(f"Error saving report to S3: {str(e)}")
            return False


def lambda_handler(event, context):
    """Lambda handler function"""
    try:
        logger.info("Starting compliance monitoring")
        
        monitor = ComplianceMonitor()
        
        # Analyze compliance
        compliance_data = monitor.analyze_compliance()
        
        # Store snapshot
        monitor.store_compliance_snapshot(compliance_data)
        
        # Generate report
        report = monitor.generate_compliance_report(compliance_data)
        
        # Save report to S3
        monitor.save_report_to_s3(report, compliance_data['timestamp'])
        
        # Send alert if needed
        monitor.send_alert_if_non_compliant(compliance_data)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Compliance monitoring completed',
                'compliance_percentage': compliance_data['compliance_percentage'],
                'non_compliant_rules': compliance_data['non_compliant_rules']
            })
        }
    
    except Exception as e:
        logger.error(f"Error in compliance monitoring: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }


class RiskAssessmentEngine:
    """Assess and score risks based on compliance findings"""
    
    RISK_SCORING_MATRIX = {
        'critical': {'probability': 0.9, 'impact': 10, 'score': 9.0},
        'high': {'probability': 0.7, 'impact': 8, 'score': 7.0},
        'medium': {'probability': 0.5, 'impact': 5, 'score': 5.0},
        'low': {'probability': 0.3, 'impact': 2, 'score': 2.0}
    }
    
    def __init__(self):
        self.risks = []
    
    def calculate_risk_score(self, probability: float, impact: int) -> float:
        """Calculate risk score using probability and impact"""
        return round(probability * impact, 2)
    
    def assess_compliance_risk(self, non_compliant_rules: int, total_rules: int) -> Dict[str, Any]:
        """Assess risk level based on compliance status"""
        non_compliance_ratio = non_compliant_rules / total_rules if total_rules > 0 else 0
        
        if non_compliance_ratio >= 0.5:
            risk_level = 'critical'
        elif non_compliance_ratio >= 0.3:
            risk_level = 'high'
        elif non_compliance_ratio >= 0.1:
            risk_level = 'medium'
        else:
            risk_level = 'low'
        
        matrix = self.RISK_SCORING_MATRIX[risk_level]
        
        return {
            'risk_level': risk_level,
            'probability': matrix['probability'],
            'impact': matrix['impact'],
            'risk_score': matrix['score'],
            'non_compliance_ratio': round(non_compliance_ratio * 100, 2)
        }


def assess_risks(event, context):
    """Lambda handler for risk assessment"""
    try:
        logger.info("Starting risk assessment")
        
        engine = RiskAssessmentEngine()
        
        # Get compliance data
        monitor = ComplianceMonitor()
        compliance_data = monitor.analyze_compliance()
        
        # Assess risks
        risk_assessment = engine.assess_compliance_risk(
            compliance_data['non_compliant_rules'],
            compliance_data['total_rules']
        )
        
        # Store risk assessment
        table = dynamodb.Table('grc-risk-register')
        table.put_item(
            Item={
                'risk_id': f"risk-{datetime.utcnow().isoformat()}",
                'risk_level': risk_assessment['risk_level'],
                'risk_score': risk_assessment['risk_score'],
                'assessment_date': datetime.utcnow().isoformat(),
                'details': json.dumps(risk_assessment)
            }
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps(risk_assessment)
        }
    
    except Exception as e:
        logger.error(f"Error in risk assessment: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
