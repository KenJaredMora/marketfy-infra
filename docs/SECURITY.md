# Security Checklist for Marketfy AWS Deployment

## 🔒 Pre-Deployment Security

### AWS Account Security
- [ ] **Enable MFA** on root account
- [ ] **Create IAM user** (don't use root for day-to-day)
- [ ] **Enable MFA** on IAM user
- [ ] **Use strong passwords** (minimum 16 characters)
- [ ] **Set up billing alerts** to detect unusual activity
- [ ] **Enable CloudTrail** for audit logging
- [ ] **Review AWS Service Quotas** to prevent resource exhaustion

### Credential Management
- [ ] **Never commit** `.env` or `.tfvars` files to git
- [ ] **Use AWS Secrets Manager** for production secrets
- [ ] **Rotate credentials** regularly (every 90 days)
- [ ] **Generate strong JWT secret** (minimum 32 characters)
- [ ] **Generate strong DB password** (minimum 20 characters)
- [ ] **Store credentials** in password manager (1Password, LastPass, Bitwarden)

### Network Security
- [ ] **Restrict IP access** in security groups (use your IP `/32`)
- [ ] **Use private subnets** for database (not publicly accessible)
- [ ] **Enable VPC Flow Logs** to monitor network traffic
- [ ] **Use NAT Gateway** for private subnet internet access
- [ ] **Enable AWS Shield** for DDoS protection (free tier)

---

## 🛡️ Infrastructure Security

### VPC and Networking
- [ ] **Use at least 2 availability zones** for high availability
- [ ] **Separate public and private subnets**
- [ ] **Database in private subnet only** (no public IP)
- [ ] **Use security groups, not NACLs** for easier management
- [ ] **Enable VPC Flow Logs** to CloudWatch

### Security Groups Configuration
```
ALB Security Group:
- Inbound: 80 (HTTP) from 0.0.0.0/0 or your IP
- Inbound: 443 (HTTPS) from 0.0.0.0/0 or your IP
- Outbound: All traffic to ECS security group

ECS Security Group:
- Inbound: 3000 (API) from ALB security group
- Inbound: 80 (Frontend) from ALB security group
- Outbound: All traffic to internet (for updates)
- Outbound: 5432 (PostgreSQL) to RDS security group

RDS Security Group:
- Inbound: 5432 from ECS security group ONLY
- Outbound: None
```

### Database (RDS)
- [ ] **Enable encryption at rest** (use AWS KMS)
- [ ] **Enable encryption in transit** (SSL/TLS)
- [ ] **Automated backups enabled** (retention 7-30 days)
- [ ] **Multi-AZ deployment** for production
- [ ] **Disable public accessibility**
- [ ] **Use strong master password**
- [ ] **Enable Enhanced Monitoring**
- [ ] **Enable Performance Insights**

### Containers (ECS/Docker)
- [ ] **Run containers as non-root user** (already configured in Dockerfiles)
- [ ] **Scan images for vulnerabilities** (use ECR image scanning)
- [ ] **Use specific image tags** (not `latest` in production)
- [ ] **Minimize image size** (use Alpine, multi-stage builds)
- [ ] **Don't store secrets in images**
- [ ] **Enable container insights** (CloudWatch)

### Load Balancer (ALB)
- [ ] **Enable access logs** to S3
- [ ] **Use HTTPS with valid certificate** (ACM)
- [ ] **Force HTTPS redirect** (redirect HTTP to HTTPS)
- [ ] **Enable deletion protection** for production
- [ ] **Configure health checks properly**
- [ ] **Set idle timeout appropriately**

---

## 🔐 Application Security

### Authentication & Authorization
- [ ] **Use strong JWT secret** (minimum 32 characters, random)
- [ ] **Set reasonable token expiration** (1 hour for access tokens)
- [ ] **Implement refresh tokens** for better security
- [ ] **Hash passwords with bcrypt** (already implemented)
- [ ] **Implement rate limiting** on login endpoints
- [ ] **Add CAPTCHA** for registration/login (optional)

### API Security
- [ ] **Validate all inputs** (class-validator already implemented)
- [ ] **Sanitize inputs** to prevent injection attacks
- [ ] **Use CORS properly** (restrict origins in production)
- [ ] **Implement rate limiting** (already implemented with Throttler)
- [ ] **Add request size limits**
- [ ] **Use Helmet.js** for security headers (already implemented)
- [ ] **Enable HTTPS only** in production
- [ ] **Validate file uploads** (size, type, content)

### Frontend Security
- [ ] **Use Content Security Policy (CSP)** headers
- [ ] **Enable XSS protection** (already in nginx config)
- [ ] **Prevent clickjacking** (X-Frame-Options: SAMEORIGIN)
- [ ] **Use SameSite cookies** for session management
- [ ] **Validate user inputs** on frontend
- [ ] **Don't expose sensitive data** in localStorage
- [ ] **Use HTTPS for all API calls**

### Environment Variables
- [ ] **Never hardcode secrets** in code
- [ ] **Use AWS Secrets Manager** for production
- [ ] **Use environment-specific configs**
- [ ] **Validate env vars on startup**
- [ ] **Don't log sensitive information**

---

## 🔍 Monitoring & Auditing

### CloudWatch
- [ ] **Set up log groups** for all services
- [ ] **Configure log retention** (7-30 days for dev, longer for prod)
- [ ] **Create alarms** for critical metrics:
  - High error rates
  - High latency
  - Memory/CPU usage
  - Failed health checks
- [ ] **Set up dashboards** for key metrics
- [ ] **Enable container insights**

### CloudTrail
- [ ] **Enable CloudTrail** in all regions
- [ ] **Log to S3 bucket** with encryption
- [ ] **Enable log file validation**
- [ ] **Set up S3 bucket policies** to prevent deletion
- [ ] **Review logs regularly** for suspicious activity
- [ ] **Set up CloudWatch alarms** for critical events:
  - Root account usage
  - IAM policy changes
  - Security group changes

### AWS Config
- [ ] **Enable AWS Config** to track resource changes
- [ ] **Set up Config Rules** for compliance:
  - S3 buckets not public
  - RDS encryption enabled
  - Root account MFA enabled
- [ ] **Review compliance dashboard** regularly

### Security Hub
- [ ] **Enable AWS Security Hub**
- [ ] **Enable default standards**:
  - AWS Foundational Security Best Practices
  - CIS AWS Foundations Benchmark
- [ ] **Review findings regularly**
- [ ] **Remediate critical/high findings** promptly

---

## 🚨 Incident Response

### Preparation
- [ ] **Document incident response plan**
- [ ] **Create runbooks** for common issues
- [ ] **Set up alerting** (email, SMS, Slack)
- [ ] **Define escalation procedures**
- [ ] **Test backup restoration** regularly

### Response Procedures
If you detect a security incident:

1. **Contain**:
   - Isolate affected resources
   - Revoke compromised credentials
   - Update security groups

2. **Investigate**:
   - Check CloudTrail logs
   - Review CloudWatch logs
   - Identify scope of breach

3. **Remediate**:
   - Patch vulnerabilities
   - Reset all credentials
   - Apply security updates

4. **Document**:
   - Record timeline
   - Document findings
   - Create post-mortem

---

## 🧹 Regular Maintenance

### Weekly
- [ ] **Review CloudWatch alarms**
- [ ] **Check for failed health checks**
- [ ] **Review application logs** for errors

### Monthly
- [ ] **Review AWS bill** for anomalies
- [ ] **Update dependencies** (npm, Docker images)
- [ ] **Review security group rules**
- [ ] **Check for unused resources**
- [ ] **Review CloudTrail logs** for suspicious activity

### Quarterly
- [ ] **Rotate credentials** (DB password, JWT secret)
- [ ] **Review IAM permissions** (remove unused)
- [ ] **Update SSL certificates** (if not using ACM)
- [ ] **Conduct security assessment**
- [ ] **Review and update documentation**

### Annually
- [ ] **Full security audit**
- [ ] **Penetration testing** (if required)
- [ ] **Disaster recovery drill**
- [ ] **Review and update policies**

---

## ⚠️ Common Vulnerabilities to Avoid

### OWASP Top 10
1. **Injection** → Use parameterized queries, validate inputs
2. **Broken Authentication** → Strong passwords, MFA, session management
3. **Sensitive Data Exposure** → Encrypt at rest and in transit
4. **XML External Entities (XXE)** → Disable XML parsing if not needed
5. **Broken Access Control** → Implement proper authorization
6. **Security Misconfiguration** → Follow this checklist!
7. **XSS** → Sanitize inputs, CSP headers
8. **Insecure Deserialization** → Validate serialized data
9. **Using Components with Known Vulnerabilities** → Keep dependencies updated
10. **Insufficient Logging** → Log all authentication attempts

---

## 📱 Emergency Contacts

Keep these handy:

- **AWS Support**: https://console.aws.amazon.com/support/
- **AWS Trust & Safety**: abuse@amazonaws.com
- **Your team's on-call**: [Add your contact info]

---

## 🎯 Production Readiness Checklist

Before going to production:

- [ ] All items in this security checklist completed
- [ ] Penetration testing conducted
- [ ] Load testing completed
- [ ] Disaster recovery plan documented and tested
- [ ] Monitoring and alerting configured
- [ ] SSL certificate installed and HTTPS enabled
- [ ] Database backups automated and tested
- [ ] Incident response plan documented
- [ ] All team members trained on security procedures
- [ ] Legal/compliance review completed (if required)

---

## 📚 Additional Resources

- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CIS AWS Foundations Benchmark](https://www.cisecurity.org/benchmark/amazon_web_services)
- [AWS Well-Architected Framework - Security Pillar](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html)

---

**Remember**: Security is not a one-time task, it's an ongoing process! 🔒
