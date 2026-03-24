/**
 * GRC Platform - React Dashboard Component
 * Main dashboard for Governance, Risk, and Compliance monitoring
 */

import React, { useState, useEffect } from 'react';
import './grc-dashboard.css';

// Mock data for demonstration
const mockComplianceData = {
  frameworks: [
    { name: 'ISO 27001:2022', compliance: 85, status: 'good' },
    { name: 'NIST CSF', compliance: 78, status: 'warning' },
    { name: 'PCI DSS', compliance: 92, status: 'good' },
    { name: 'HIPAA', compliance: 88, status: 'good' },
    { name: 'GDPR', compliance: 81, status: 'warning' },
    { name: 'SOC 2', compliance: 90, status: 'good' }
  ],
  risks: [
    { id: 'RISK-001', title: 'Unauthorized Access', level: 'critical', score: 9.0 },
    { id: 'RISK-002', title: 'Data Breach', level: 'high', score: 7.5 },
    { id: 'RISK-003', title: 'Compliance Violation', level: 'high', score: 7.0 },
    { id: 'RISK-004', title: 'System Downtime', level: 'medium', score: 5.0 }
  ],
  controls: {
    total: 45,
    implemented: 38,
    inProgress: 5,
    notStarted: 2
  },
  assets: {
    total: 12,
    critical: 4,
    high: 5,
    medium: 3
  }
};

// Compliance Status Card Component
const ComplianceCard = ({ framework }) => {
  const getStatusColor = (status) => {
    switch (status) {
      case 'good':
        return '#10b981';
      case 'warning':
        return '#f59e0b';
      case 'critical':
        return '#ef4444';
      default:
        return '#6b7280';
    }
  };

  return (
    <div className="compliance-card">
      <div className="card-header">
        <h3>{framework.name}</h3>
        <span className="compliance-badge" style={{ backgroundColor: getStatusColor(framework.status) }}>
          {framework.compliance}%
        </span>
      </div>
      <div className="progress-bar">
        <div
          className="progress-fill"
          style={{
            width: `${framework.compliance}%`,
            backgroundColor: getStatusColor(framework.status)
          }}
        />
      </div>
      <p className="compliance-text">Compliance Score: {framework.compliance}%</p>
    </div>
  );
};

// Risk Card Component
const RiskCard = ({ risk }) => {
  const getRiskColor = (level) => {
    switch (level) {
      case 'critical':
        return '#dc2626';
      case 'high':
        return '#ea580c';
      case 'medium':
        return '#f59e0b';
      case 'low':
        return '#10b981';
      default:
        return '#6b7280';
    }
  };

  return (
    <div className="risk-card" style={{ borderLeft: `4px solid ${getRiskColor(risk.level)}` }}>
      <div className="risk-header">
        <h4>{risk.title}</h4>
        <span className="risk-badge" style={{ backgroundColor: getRiskColor(risk.level) }}>
          {risk.level.toUpperCase()}
        </span>
      </div>
      <p className="risk-id">{risk.id}</p>
      <p className="risk-score">Risk Score: {risk.score}/10</p>
    </div>
  );
};

// Control Status Component
const ControlStatus = ({ controls }) => {
  const total = controls.total;
  const implemented = controls.implemented;
  const inProgress = controls.inProgress;
  const notStarted = controls.notStarted;

  return (
    <div className="control-status">
      <h3>Control Implementation Status</h3>
      <div className="control-stats">
        <div className="stat-item">
          <span className="stat-label">Total Controls</span>
          <span className="stat-value">{total}</span>
        </div>
        <div className="stat-item implemented">
          <span className="stat-label">Implemented</span>
          <span className="stat-value">{implemented}</span>
        </div>
        <div className="stat-item in-progress">
          <span className="stat-label">In Progress</span>
          <span className="stat-value">{inProgress}</span>
        </div>
        <div className="stat-item not-started">
          <span className="stat-label">Not Started</span>
          <span className="stat-value">{notStarted}</span>
        </div>
      </div>
      <div className="control-progress">
        <div className="progress-segment implemented" style={{ width: `${(implemented / total) * 100}%` }} />
        <div className="progress-segment in-progress" style={{ width: `${(inProgress / total) * 100}%` }} />
        <div className="progress-segment not-started" style={{ width: `${(notStarted / total) * 100}%` }} />
      </div>
    </div>
  );
};

// Asset Inventory Component
const AssetInventory = ({ assets }) => {
  return (
    <div className="asset-inventory">
      <h3>Asset Inventory</h3>
      <div className="asset-stats">
        <div className="asset-item">
          <span className="asset-label">Total Assets</span>
          <span className="asset-value">{assets.total}</span>
        </div>
        <div className="asset-item critical">
          <span className="asset-label">Critical</span>
          <span className="asset-value">{assets.critical}</span>
        </div>
        <div className="asset-item high">
          <span className="asset-label">High</span>
          <span className="asset-value">{assets.high}</span>
        </div>
        <div className="asset-item medium">
          <span className="asset-label">Medium</span>
          <span className="asset-value">{assets.medium}</span>
        </div>
      </div>
    </div>
  );
};

// Main Dashboard Component
const GRCDashboard = () => {
  const [activeTab, setActiveTab] = useState('overview');
  const [complianceData, setComplianceData] = useState(mockComplianceData);
  const [lastUpdated, setLastUpdated] = useState(new Date().toLocaleString());

  useEffect(() => {
    // In production, this would fetch data from AWS Lambda/API Gateway
    // const fetchData = async () => {
    //   try {
    //     const response = await fetch('https://api.grc-platform.com/compliance-status');
    //     const data = await response.json();
    //     setComplianceData(data);
    //   } catch (error) {
    //     console.error('Error fetching compliance data:', error);
    //   }
    // };
    // fetchData();
  }, []);

  const calculateAverageCompliance = () => {
    const avg = complianceData.frameworks.reduce((sum, f) => sum + f.compliance, 0) / complianceData.frameworks.length;
    return Math.round(avg);
  };

  const getCriticalRisks = () => {
    return complianceData.risks.filter(r => r.level === 'critical').length;
  };

  return (
    <div className="grc-dashboard">
      {/* Header */}
      <header className="dashboard-header">
        <div className="header-content">
          <h1>GRC Platform Dashboard</h1>
          <p className="subtitle">Governance, Risk, and Compliance Monitoring</p>
        </div>
        <div className="header-info">
          <span className="last-updated">Last Updated: {lastUpdated}</span>
          <button className="refresh-btn">Refresh</button>
        </div>
      </header>

      {/* Navigation Tabs */}
      <nav className="dashboard-nav">
        <button
          className={`nav-tab ${activeTab === 'overview' ? 'active' : ''}`}
          onClick={() => setActiveTab('overview')}
        >
          Overview
        </button>
        <button
          className={`nav-tab ${activeTab === 'compliance' ? 'active' : ''}`}
          onClick={() => setActiveTab('compliance')}
        >
          Compliance
        </button>
        <button
          className={`nav-tab ${activeTab === 'risks' ? 'active' : ''}`}
          onClick={() => setActiveTab('risks')}
        >
          Risks
        </button>
        <button
          className={`nav-tab ${activeTab === 'controls' ? 'active' : ''}`}
          onClick={() => setActiveTab('controls')}
        >
          Controls
        </button>
        <button
          className={`nav-tab ${activeTab === 'assets' ? 'active' : ''}`}
          onClick={() => setActiveTab('assets')}
        >
          Assets
        </button>
      </nav>

      {/* Main Content */}
      <main className="dashboard-content">
        {/* Overview Tab */}
        {activeTab === 'overview' && (
          <div className="tab-content overview">
            {/* KPI Cards */}
            <div className="kpi-grid">
              <div className="kpi-card">
                <h3>Average Compliance</h3>
                <div className="kpi-value" style={{ color: '#10b981' }}>
                  {calculateAverageCompliance()}%
                </div>
                <p>Across all frameworks</p>
              </div>
              <div className="kpi-card">
                <h3>Critical Risks</h3>
                <div className="kpi-value" style={{ color: '#dc2626' }}>
                  {getCriticalRisks()}
                </div>
                <p>Requiring immediate attention</p>
              </div>
              <div className="kpi-card">
                <h3>Controls Implemented</h3>
                <div className="kpi-value" style={{ color: '#3b82f6' }}>
                  {complianceData.controls.implemented}/{complianceData.controls.total}
                </div>
                <p>{Math.round((complianceData.controls.implemented / complianceData.controls.total) * 100)}% Complete</p>
              </div>
              <div className="kpi-card">
                <h3>Critical Assets</h3>
                <div className="kpi-value" style={{ color: '#f59e0b' }}>
                  {complianceData.assets.critical}
                </div>
                <p>Requiring protection</p>
              </div>
            </div>

            {/* Compliance Summary */}
            <section className="section">
              <h2>Compliance Summary</h2>
              <div className="compliance-grid">
                {complianceData.frameworks.map((framework, index) => (
                  <ComplianceCard key={index} framework={framework} />
                ))}
              </div>
            </section>

            {/* Risk Summary */}
            <section className="section">
              <h2>Top Risks</h2>
              <div className="risk-grid">
                {complianceData.risks.slice(0, 4).map((risk, index) => (
                  <RiskCard key={index} risk={risk} />
                ))}
              </div>
            </section>
          </div>
        )}

        {/* Compliance Tab */}
        {activeTab === 'compliance' && (
          <div className="tab-content compliance">
            <section className="section">
              <h2>Compliance Frameworks</h2>
              <div className="compliance-grid">
                {complianceData.frameworks.map((framework, index) => (
                  <ComplianceCard key={index} framework={framework} />
                ))}
              </div>
            </section>
          </div>
        )}

        {/* Risks Tab */}
        {activeTab === 'risks' && (
          <div className="tab-content risks">
            <section className="section">
              <h2>Risk Register</h2>
              <div className="risk-grid">
                {complianceData.risks.map((risk, index) => (
                  <RiskCard key={index} risk={risk} />
                ))}
              </div>
            </section>
          </div>
        )}

        {/* Controls Tab */}
        {activeTab === 'controls' && (
          <div className="tab-content controls">
            <section className="section">
              <ControlStatus controls={complianceData.controls} />
            </section>
          </div>
        )}

        {/* Assets Tab */}
        {activeTab === 'assets' && (
          <div className="tab-content assets">
            <section className="section">
              <AssetInventory assets={complianceData.assets} />
            </section>
          </div>
        )}
      </main>

      {/* Footer */}
      <footer className="dashboard-footer">
        <p>&copy; 2026 GRC Platform. All rights reserved.</p>
        <p>AWS Integrated Governance, Risk, and Compliance Solution</p>
      </footer>
    </div>
  );
};

export default GRCDashboard;
