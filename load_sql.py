import json
import pymysql

DB_HOST = 'grc-capstone-db.cnok20k42m82.us-east-1.rds.amazonaws.com'
DB_USER = 'grcadmin'
DB_PASS = 'GrcPass2026!'
DB_NAME = 'grcdb'

SQL = """
CREATE TABLE IF NOT EXISTS frameworks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    version VARCHAR(50),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS controls (
    id INT AUTO_INCREMENT PRIMARY KEY,
    control_id VARCHAR(50) NOT NULL,
    framework_id INT,
    title VARCHAR(200),
    description TEXT,
    implementation_status VARCHAR(50) DEFAULT 'not_implemented',
    owner VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS risks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    risk_id VARCHAR(50) NOT NULL,
    title VARCHAR(200),
    description TEXT,
    category VARCHAR(100),
    probability DECIMAL(3,2),
    impact DECIMAL(3,2),
    risk_score DECIMAL(4,2),
    status VARCHAR(50) DEFAULT 'open',
    owner VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS audit_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    action VARCHAR(100),
    entity_type VARCHAR(100),
    entity_id VARCHAR(100),
    user_name VARCHAR(100),
    details TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO frameworks (name, version, description) VALUES
('ISO 27001', '2022', 'Information Security Management System'),
('NIST CSF', '1.1', 'Cybersecurity Framework'),
('PCI DSS', '3.2.1', 'Payment Card Industry Data Security Standard'),
('HIPAA', '2013', 'Health Insurance Portability and Accountability Act'),
('GDPR', '2018', 'General Data Protection Regulation'),
('SOC 2', '2017', 'Service Organization Control 2');

INSERT INTO controls (control_id, framework_id, title, implementation_status, owner) VALUES
('ISO-A.5.1', 1, 'Information Security Policies', 'implemented', 'CISO'),
('ISO-A.6.1', 1, 'Organisation of Information Security', 'implemented', 'CISO'),
('ISO-A.8.1', 1, 'Asset Management', 'in_progress', 'IT Manager'),
('NIST-ID.AM', 2, 'Asset Management', 'implemented', 'IT Manager'),
('NIST-PR.AC', 2, 'Access Control', 'implemented', 'Security Team'),
('PCI-1.1', 3, 'Network Security Controls', 'implemented', 'Network Team'),
('PCI-2.1', 3, 'Secure Configurations', 'in_progress', 'IT Manager'),
('HIPAA-164.312', 4, 'Technical Safeguards', 'implemented', 'IT Manager'),
('GDPR-Art.32', 5, 'Security of Processing', 'implemented', 'DPO'),
('SOC2-CC6.1', 6, 'Logical Access Controls', 'implemented', 'Security Team');

INSERT INTO risks (risk_id, title, category, probability, impact, risk_score, status, owner) VALUES
('RSK-001', 'Unauthorized Access to Systems', 'Access Control', 0.3, 0.9, 5.4, 'open', 'CISO'),
('RSK-002', 'Data Breach via Phishing', 'Social Engineering', 0.5, 0.8, 6.4, 'in_progress', 'Security Team'),
('RSK-003', 'Ransomware Attack', 'Malware', 0.2, 1.0, 5.0, 'open', 'IT Manager'),
('RSK-004', 'Insider Threat', 'Human Factor', 0.2, 0.8, 4.0, 'open', 'HR'),
('RSK-005', 'Third Party Vendor Risk', 'Supply Chain', 0.4, 0.7, 5.6, 'in_progress', 'Procurement'),
('RSK-006', 'DDoS Attack', 'Availability', 0.3, 0.6, 4.2, 'open', 'Network Team');

INSERT INTO audit_logs (action, entity_type, entity_id, user_name, details) VALUES
('CREATE', 'framework', '1', 'admin', 'ISO 27001 framework added'),
('CREATE', 'framework', '2', 'admin', 'NIST CSF framework added'),
('UPDATE', 'control', 'ISO-A.8.1', 'jsmith', 'Status updated to in_progress'),
('CREATE', 'risk', 'RSK-001', 'admin', 'New risk identified'),
('UPDATE', 'risk', 'RSK-002', 'jdoe', 'Risk mitigation started');
"""

def lambda_handler(event, context):
    try:
        conn = pymysql.connect(
            host=DB_HOST,
            user=DB_USER,
            password=DB_PASS,
            database=DB_NAME,
            connect_timeout=10
        )
        cursor = conn.cursor()
        for statement in SQL.strip().split(';'):
            if statement.strip():
                cursor.execute(statement)
        conn.commit()
        cursor.execute("SHOW TABLES;")
        tables = cursor.fetchall()
        conn.close()
        return {
            "statusCode": 200,
            "body": json.dumps({"message": "Data loaded!", "tables": [t[0] for t in tables]})
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
