---
name: Workshop Resource Request Form
about: Workshop leads may use this form to request computing resources (AWS, Google Cloud, NSF ACCESS or CIROH-2i2c JupyterHub) for CIROH workshops. Access is available to all consortium members and partners.
title: 'Workshop Resource Request: [Workshop Name]'
labels: workshop, infrastructure
assignees: ''
---

## 1. Workshop Lead Information
*Please provide contact information for the workshop lead/instructor.*
- Full Name:
- Affiliated Institute:
- Email Address:

## 2. Workshop Information
*Provide a brief description of the workshop and its learning objectives.*
- Conference Name:
- Workshop Title:
- Workshop Date(s):
- Workshop Duration (hours/days):
- Expected Number of Participants:

## 3. Workshop Description
*Briefly describe the workshop content, activities, and any software that participants will use or develop.*

## 4. Resource Requirements
*Specify the computing resources needed for the workshop. Be as specific as possible about configurations and capabilities needed.*

### 4.1. Resource Type (select one or more)
- [ ] AWS Cloud
- [ ] Google Cloud
- [ ] CIROH-2i2c JupyterHub
- [ ] NSF ACCESS Allocation

### 4.2. Per-User Resource Requirements
*Specify resources needed per workshop participant*
- Number of vCPUs per user:
- Memory (GB) per user:
- Storage (GB) per user:
- GPU requirements (if any):

### 4.3. Specific Service Requirements

#### For Cloud Resources (AWS/Google Cloud)
*Check all services that will be needed during the workshop:*

##### AWS Services
- [ ] EC2 - Specify instance type(s):
- [ ] S3 - Specify bucket type (public/private):
- [ ] EBS (Amazon Elastic Block Store)
- [ ] RDS
- [ ] VPC (Virtual Private Cloud)
- [ ] Lambda
- [ ] ArcGIS on AWS
- [ ] Other AWS services (please list):

##### Google Cloud Services
- [ ] Google Compute Engine - Specify instance type(s):
- [ ] Google Cloud Storage
- [ ] Google BigQuery (Note: we will provide one key per workshop)
- [ ] Google Cloud Functions
- [ ] Other Google services (please list):

#### For CIROH-2i2c JupyterHub Resources
- [ ] Small - 5GB RAM, 2 CPUs
- [ ] Medium - 11GB RAM, 4 CPUs
- [ ] Large - 24GB RAM, 8CPUs
- [ ] Huge - 52GB RAM, 16 CPUs
- [ ] GPU - NVIDIA Tesla T4, ~16GB, ~4 CPUs
- [ ] Custom environment (please specify packages below)
- Required Python packages with version:
- Other required software:

#### For On-premise VM Resources (NSF ACCESS)
- Number of VMs:
- CPUs per node:
- Memory per node:
- Required software modules:

## 5. Workshop User Management
*Provide details on how users will be managed and authenticated.*
- Will participants need individual accounts? (Yes/No):
- Will you provide a list of participant emails? (Yes/No):
- Do participants need persistent storage beyond the workshop? (Yes/No):

## 6. Workshop Timeline
*Indicate when resources should be available and for how long.*
- Resource availability start date (for setup/testing):
- Workshop date(s):
- Resource teardown date:
- Will resources be needed after the workshop ends? (Yes/No and duration):

## 7. Security and Compliance Requirements
*If there are any specific security or compliance requirements for the workshop, please specify them.*

## 8. Cost Estimation
*For cloud resources, please provide an estimated cost for the workshop duration.*
- AWS Cost Calculator: https://calculator.aws/#/
- Google Cloud Pricing Calculator: https://cloud.google.com/products/calculator

## 9. Additional Information
*Any other details that would help us support your workshop.*

## 10. Working Group Affiliation
Working Group 1/2/3/4 (select one): 

## 11. Approval
*Please indicate any approval processes needed for this request.*

---

### Resource Information Links:
- CIROH-2i2c JupyterHub: [JupyterHub Documentation](https://docs.ciroh.org/docs/services/cloudservices/jupyterhub/)
- NSF ACCESS: [ACCESS Resource Allocations](https://allocations.access-ci.org/resources)
