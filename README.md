# Azure Application Gateway with Web Application Firewall (WAF)

This project demonstrates the implementation of an **Azure Application Gateway** integrated with **Azure Web Application Firewall (WAF)** using **Bicep (Infrastructure as Code)**. The infrastructure was developed and managed using **Visual Studio Code**, version-controlled with **GitHub**, and deployed through **Azure CLI/GitHub Actions**.

The Application Gateway routes traffic to two backend virtual machines using **path-based routing** and protects the application against common web attacks such as **SQL Injection** by using Azure WAF in **Prevention Mode**.

---

## Project Overview

### Objectives

- Configure Azure Application Gateway using Bicep.
- Enable Azure Web Application Firewall (WAF).
- Route requests to multiple backend virtual machines.
- Implement path-based routing (`/app1` and `/app2`).
- Block malicious requests using Azure WAF.
- Manage infrastructure through Visual Studio Code and GitHub.

---

## Architecture

```text
                    Internet
                        │
                        ▼
        Azure Application Gateway (WAF_v2)
                        │
          ┌─────────────┴─────────────┐
          │                           │
       /app1/*                     /app2/*
          │                           │
          ▼                           ▼
      VM-APP-1                    VM-APP-2
    (172.16.0.4)                (172.16.0.5)

Malicious Requests
        │
        ▼
 Azure WAF (Prevention Mode)
        │
        ▼
   403 Forbidden
```

---

## Technologies Used

| Technology | Purpose |
|------------|---------|
| Azure Application Gateway | Load balancing and request routing |
| Azure Web Application Firewall | Web application security |
| Bicep | Infrastructure as Code |
| Azure Virtual Machines | Backend web servers |
| Visual Studio Code | Development environment |
| Azure CLI | Infrastructure deployment |
| Git & GitHub | Version control and CI/CD |

---

## Project Structure

```text
AZURE_APPLICATION_GATEWAY_WAF
│
├── App
│   ├── App1
│   │   └── index.html
│   └── App2
│       └── index.html
│
├── Infra
│   └── main.bicep
│
├── .github
│   └── workflows
│       └── deploy.yml
│
├── .gitignore
└── README.md
```

---

## Features Implemented

- Azure Application Gateway (WAF_v2 SKU).
- Azure WAF Policy in **Prevention Mode**.
- Backend pools for two virtual machines.
- HTTP health probes for backend monitoring.
- Path-based routing using URL Path Maps.
- Static Public IP for the Application Gateway.
- Deployment through Bicep using Azure CLI/GitHub.

---

## Backend Configuration

| Backend VM | Private IP | Route |
|------------|------------|-------|
| VM-APP-1 | `172.16.0.4` | `/app1/*` |
| VM-APP-2 | `172.16.0.5` | `/app2/*` |

---

## Testing the Application

### Application Routing

**VM APP 1**

URL:

```text
http://<ApplicationGatewayPublicIP>/app1/
```

Expected Output:

```text
VM APP 1 WORKING
Backend Server 1 reached through Azure Application Gateway + WAF.
```

**VM APP 2**

URL:

```text
http://<ApplicationGatewayPublicIP>/app2/
```

Expected Output:

```text
VM APP 2 WORKING
Backend Server 2 reached through Azure Application Gateway + WAF.
```

---

## Web Application Firewall Testing

Azure WAF blocks malicious requests before they reach the backend virtual machines.

### SQL Injection Test

Example request:

```text
http://<ApplicationGatewayPublicIP>/?id=1+union+select+1
```

Expected Response:

```text
403 Forbidden
Microsoft-Azure-Application-Gateway/v2
```

This confirms that the WAF detects and blocks SQL injection attempts.

---

## Deployment Steps

1. Clone the repository.
2. Open the project in Visual Studio Code.
3. Sign in to Azure using Azure CLI.
4. Deploy the infrastructure using the Bicep template.
5. Verify Application Gateway routing.
6. Test WAF protection using a SQL injection request.

### Azure CLI Deployment

```bash
az login

az deployment group create \
  --resource-group <RESOURCE_GROUP_NAME> \
  --template-file Infra/main.bicep
```

---

## Expected Results

| Test | Expected Result |
|------|-----------------|
| `/app1/` | VM APP 1 WORKING |
| `/app2/` | VM APP 2 WORKING |
| SQL Injection URL | 403 Forbidden |
| Healthy backend pools | Both VMs marked Healthy |

---

## Learning Outcomes

This project helped me understand:

- Azure Application Gateway configuration using Bicep.
- Azure Web Application Firewall (WAF) policy configuration.
- Path-based routing with backend pools.
- Infrastructure as Code (IaC) using Bicep.
- GitHub-based infrastructure version control and deployment.
- Security validation using Azure WAF in Prevention Mode.

---

## Author

**Bhagy Yelleti**

Azure Application Gateway with Web Application Firewall (WAF) project developed using **Azure, Bicep, Visual Studio Code, Git, GitHub, and Azure CLI**.
