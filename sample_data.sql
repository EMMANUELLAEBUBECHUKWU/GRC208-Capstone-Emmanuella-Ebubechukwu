-- GRC Platform Sample Data
-- This script populates the database with sample compliance frameworks, controls, and risks

USE grcdb;

-- Create Tables
CREATE TABLE IF NOT EXISTS frameworks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    version VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS controls (
    id INT AUTO_INCREMENT PRIMARY KEY,
    control_id VARCHAR(100) NOT NULL UNIQUE,
    framework_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    objective TEXT,
    implementation_status ENUM('Not Started', 'In Progress', 'Implemented', 'Optimized') DEFAULT 'Not Started',
    owner VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (framework_id) REFERENCES frameworks(id)
);

CREATE TABLE IF NOT EXISTS risks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    risk_id VARCHAR(100) NOT NULL UNIQUE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    probability ENUM('Low', 'Medium', 'High', 'Critical') DEFAULT 'Medium',
    impact ENUM('Low', 'Medium', 'High', 'Critical') DEFAULT 'Medium',
    risk_score DECIMAL(5, 2),
    status ENUM('Open', 'In Progress', 'Mitigated', 'Accepted', 'Closed') DEFAULT 'Open',
    owner VARCHAR(255),
    mitigation_strategy TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS assets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    asset_id VARCHAR(100) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    type ENUM('Data', 'System', 'Application', 'Infrastructure', 'Personnel') DEFAULT 'Data',
    classification ENUM('Public', 'Internal', 'Confidential', 'Restricted') DEFAULT 'Internal',
    owner VARCHAR(255),
    criticality ENUM('Low', 'Medium', 'High', 'Critical') DEFAULT 'Medium',
    rpo_hours INT,
    rto_hours INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS audit_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    action VARCHAR(255) NOT NULL,
    entity_type VARCHAR(100),
    entity_id VARCHAR(100),
    user VARCHAR(255),
    details TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert Frameworks
INSERT INTO frameworks (name, description, version) VALUES
('ISO 27001:2022', 'Information Security Management System Standard', '2022'),
('NIST Cybersecurity Framework', 'Framework for managing cybersecurity risk', '1.1'),
('PCI DSS', 'Payment Card Industry Data Security Standard', '3.2.1'),
('HIPAA', 'Health Insurance Portability and Accountability Act', '2013'),
('GDPR', 'General Data Protection Regulation', '2018'),
('SOC 2', 'Service Organization Control Framework', '2022');

-- Insert ISO 27001 Controls
INSERT INTO controls (control_id, framework_id, title, description, objective, implementation_status, owner) VALUES
('A.5.1', 1, 'Information Security Policies', 'Management shall approve and issue information security policies', 'Establish and maintain information security policies', 'Implemented', 'CISO'),
('A.6.1', 1, 'Information Security Roles and Responsibilities', 'Allocate information security responsibilities', 'Define clear roles and responsibilities', 'Implemented', 'CISO'),
('A.7.1', 1, 'Access Control', 'Limit access to information and information processing facilities', 'Implement access control mechanisms', 'In Progress', 'Security Team'),
('A.8.1', 1, 'Cryptography', 'Protect information with cryptographic controls', 'Implement encryption standards', 'Implemented', 'Security Team'),
('A.9.1', 1, 'Physical and Environmental Security', 'Protect physical facilities and equipment', 'Secure physical access', 'Implemented', 'Facilities'),
('A.10.1', 1, 'Operations Security', 'Ensure correct and secure operations', 'Implement operational controls', 'In Progress', 'Operations Team');

-- Insert NIST Controls
INSERT INTO controls (control_id, framework_id, title, description, objective, implementation_status, owner) VALUES
('ID.AM-1', 2, 'Asset Management', 'Organizational assets are inventoried', 'Maintain asset inventory', 'Implemented', 'Asset Manager'),
('PR.AC-1', 2, 'Access Control', 'Access to physical and logical assets is managed', 'Control access to resources', 'Implemented', 'Security Team'),
('DE.CM-1', 2, 'Detection and Analysis', 'The network is monitored to detect potential cybersecurity events', 'Monitor network activity', 'In Progress', 'SOC'),
('RS.RP-1', 2, 'Response Planning', 'Response processes and procedures are executed', 'Prepare incident response', 'Implemented', 'Incident Response Team'),
('RC.RP-1', 2, 'Recovery Planning', 'Recovery processes are executed', 'Plan recovery procedures', 'Not Started', 'Recovery Team');

-- Insert PCI DSS Controls
INSERT INTO controls (control_id, framework_id, title, description, objective, implementation_status, owner) VALUES
('1.1', 3, 'Firewall Configuration', 'Establish firewall and router configuration standards', 'Protect cardholder data', 'Implemented', 'Network Team'),
('2.1', 3, 'Default Passwords', 'Change vendor-supplied defaults', 'Secure systems', 'Implemented', 'System Admin'),
('3.2', 3, 'Data Retention', 'Do not store sensitive authentication data', 'Minimize risk', 'Implemented', 'Data Team'),
('6.2', 3, 'Security Patches', 'Ensure all system components are protected', 'Patch management', 'In Progress', 'Patch Management'),
('8.1', 3, 'User Access', 'Assign unique ID to each user', 'Track user activity', 'Implemented', 'IAM Team');

-- Insert Sample Risks
INSERT INTO risks (risk_id, title, description, category, probability, impact, risk_score, status, owner, mitigation_strategy) VALUES
('RISK-001', 'Unauthorized Access to Sensitive Data', 'Potential unauthorized access to customer data due to weak access controls', 'Security', 'High', 'Critical', 9.0, 'In Progress', 'CISO', 'Implement MFA and strengthen access controls'),
('RISK-002', 'Data Breach from External Threat', 'Risk of data breach from external attackers', 'Security', 'Medium', 'Critical', 7.5, 'Open', 'Security Team', 'Implement advanced threat detection'),
('RISK-003', 'Compliance Violation', 'Risk of non-compliance with regulatory requirements', 'Compliance', 'Medium', 'High', 7.0, 'In Progress', 'Compliance Officer', 'Implement compliance monitoring'),
('RISK-004', 'System Downtime', 'Risk of system unavailability affecting business operations', 'Operational', 'Low', 'High', 5.0, 'Open', 'Operations Manager', 'Implement redundancy and failover'),
('RISK-005', 'Insider Threat', 'Risk of malicious actions by internal users', 'Security', 'Low', 'Critical', 6.5, 'Mitigated', 'Security Team', 'Implement user behavior analytics'),
('RISK-006', 'Third-party Risk', 'Risk from insecure third-party integrations', 'Vendor', 'Medium', 'Medium', 5.0, 'Open', 'Vendor Manager', 'Conduct vendor security assessments');

-- Insert Sample Assets
INSERT INTO assets (asset_id, name, type, classification, owner, criticality, rpo_hours, rto_hours) VALUES
('ASSET-001', 'Customer Database', 'Data', 'Restricted', 'Database Admin', 'Critical', 1, 4),
('ASSET-002', 'Payment Processing System', 'Application', 'Restricted', 'App Owner', 'Critical', 1, 2),
('ASSET-003', 'Email System', 'System', 'Confidential', 'IT Manager', 'High', 4, 8),
('ASSET-004', 'Web Application', 'Application', 'Confidential', 'Dev Team', 'High', 2, 4),
('ASSET-005', 'Backup Storage', 'Infrastructure', 'Confidential', 'Storage Admin', 'High', 24, 24),
('ASSET-006', 'Employee Records', 'Data', 'Confidential', 'HR Manager', 'Medium', 8, 16);

-- Insert Sample Audit Logs
INSERT INTO audit_logs (action, entity_type, entity_id, user, details) VALUES
('CREATE', 'Risk', 'RISK-001', 'admin@company.com', 'Created new risk: Unauthorized Access'),
('UPDATE', 'Control', 'A.7.1', 'security@company.com', 'Updated implementation status to In Progress'),
('CREATE', 'Asset', 'ASSET-001', 'admin@company.com', 'Registered new critical asset'),
('UPDATE', 'Risk', 'RISK-002', 'ciso@company.com', 'Updated risk status and mitigation strategy'),
('DELETE', 'Control', 'OLD-CONTROL', 'admin@company.com', 'Removed deprecated control'),
('CREATE', 'Framework', 'ISO-27001', 'compliance@company.com', 'Added ISO 27001 framework'),
('UPDATE', 'Asset', 'ASSET-005', 'storage@company.com', 'Updated RPO/RTO values'),
('CREATE', 'Risk', 'RISK-006', 'vendor@company.com', 'Identified third-party risk');

-- Create Views for Compliance Reporting
CREATE VIEW compliance_summary AS
SELECT 
    f.name as framework,
    COUNT(c.id) as total_controls,
    SUM(CASE WHEN c.implementation_status = 'Implemented' THEN 1 ELSE 0 END) as implemented,
    SUM(CASE WHEN c.implementation_status = 'In Progress' THEN 1 ELSE 0 END) as in_progress,
    SUM(CASE WHEN c.implementation_status = 'Not Started' THEN 1 ELSE 0 END) as not_started,
    ROUND(SUM(CASE WHEN c.implementation_status = 'Implemented' THEN 1 ELSE 0 END) / COUNT(c.id) * 100, 2) as compliance_percentage
FROM frameworks f
LEFT JOIN controls c ON f.id = c.framework_id
GROUP BY f.id, f.name;

CREATE VIEW risk_summary AS
SELECT 
    category,
    COUNT(*) as total_risks,
    SUM(CASE WHEN status = 'Open' THEN 1 ELSE 0 END) as open_risks,
    SUM(CASE WHEN status = 'In Progress' THEN 1 ELSE 0 END) as in_progress_risks,
    SUM(CASE WHEN status = 'Mitigated' THEN 1 ELSE 0 END) as mitigated_risks,
    AVG(risk_score) as average_risk_score
FROM risks
GROUP BY category;

CREATE VIEW critical_assets_view AS
SELECT 
    asset_id,
    name,
    type,
    classification,
    criticality,
    rpo_hours,
    rto_hours
FROM assets
WHERE criticality IN ('Critical', 'High')
ORDER BY criticality DESC;

-- Create Indexes for Performance
CREATE INDEX idx_control_framework ON controls(framework_id);
CREATE INDEX idx_control_status ON controls(implementation_status);
CREATE INDEX idx_risk_status ON risks(status);
CREATE INDEX idx_risk_category ON risks(category);
CREATE INDEX idx_asset_criticality ON assets(criticality);
CREATE INDEX idx_audit_timestamp ON audit_logs(timestamp);

-- Display Summary
SELECT 'GRC Platform Sample Data Loaded Successfully' as status;
SELECT * FROM compliance_summary;
