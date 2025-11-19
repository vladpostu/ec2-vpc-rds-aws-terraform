# AWS 2-Tier Architecture (Terraform)

A secure infrastructure project deploying a **Public Web Server (EC2)** and a **Private Database (RDS)** inside a custom VPC using Terraform.

## Architecture
* **Public Subnet:** EC2 Instance (Apache Web Server + MySQL Client).
* **Private Subnet:** RDS MySQL Instance (Isolated, no internet access).
* **Security:** Custom VPC, Route Tables, and strict Security Groups.

## Quick Start

### Prerequisites
* AWS CLI configured (`aws configure`).
* An existing EC2 Key Pair in your region.

### Deploy
1.  Initialize Terraform:
    ```bash
    terraform init
    ```
2.  Apply the configuration:
    ```bash
    terraform apply
    ```
    * *Enter your Public IP when prompted (e.g., `1.2.3.4/32`) to allow SSH access.*

### Verify
Check the outputs for the Web Server IP and Database Endpoint.

## Cleanup
To avoid costs, destroy the resources when finished:
```bash
terraform destroy