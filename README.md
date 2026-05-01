# infra-as-code-pipeline

A production-grade AWS infrastructure provisioned with Terraform and deployed via a GitHub Actions CI/CD pipeline. Infrastructure is codified, versioned, and reproducible across dev, staging, and production environments.

---

## Architecture Diagram

```
                          ┌─────────────────────────────────────────────────────┐
                          │                    AWS Cloud (ap-south-1)            │
                          │                                                       │
  Internet ──────────────►│  ┌─────────────────────────────────────────────────┐ │
                          │  │              VPC (10.x.0.0/16)                  │ │
                          │  │                                                  │ │
                          │  │  ┌──────────────┐    ┌──────────────┐           │ │
                          │  │  │Public Subnet │    │Public Subnet │           │ │
                          │  │  │ ap-south-1a  │    │ ap-south-1b  │           │ │
                          │  │  │  ┌────────┐  │    │              │           │ │
                          │  │  │  │  ALB   │  │    │              │           │ │
                          │  │  │  └───┬────┘  │    │              │           │ │
                          │  │  │  ┌───┴────┐  │    │  ┌────────┐  │           │ │
                          │  │  │  │  IGW   │  │    │  │  NAT   │  │           │ │
                          │  │  │  └────────┘  │    │  └────────┘  │           │ │
                          │  │  └──────────────┘    └──────────────┘           │ │
                          │  │                                                  │ │
                          │  │  ┌──────────────┐    ┌──────────────┐           │ │
                          │  │  │Private Subnet│    │Private Subnet│           │ │
                          │  │  │ ap-south-1a  │    │ ap-south-1b  │           │ │
                          │  │  │ ┌──────────┐ │    │ ┌──────────┐ │           │ │
                          │  │  │ │ECS Fargate│ │    │ │ECS Fargate│ │           │ │
                          │  │  │ │  Tasks   │ │    │ │  Tasks   │ │           │ │
                          │  │  │ └──────────┘ │    │ └──────────┘ │           │ │
                          │  │  └──────────────┘    └──────────────┘           │ │
                          │  │                                                  │ │
                          │  │  ┌──────────────────────────────────────────┐   │ │
                          │  │  │              ECR Repository               │   │ │
                          │  │  └──────────────────────────────────────────┘   │ │
                          │  └─────────────────────────────────────────────────┘ │
                          │                                                       │
                          │  CloudWatch Logs │ CloudWatch Alarms │ Dashboard      │
                          └─────────────────────────────────────────────────────┘
```

---

## Pipeline Flow Diagram

```
  Developer pushes code
         │
         ▼
  ┌─────────────┐
  │  GitHub PR  │──────────────────────────────────────────────────────┐
  └──────┬──────┘                                                       │
         │                                                              │
         ▼                                                              │
  ┌─────────────┐     fail                                             │
  │    Lint     │──────────► ❌ Pipeline stops                         │
  │ tf validate │                                                       │
  │   tflint    │                                                       │
  └──────┬──────┘                                                       │
         │ pass                                                         │
         ▼                                                              │
  ┌─────────────┐     fail                                             │
  │Docker Build │──────────► ❌ Pipeline stops                         │
  │Health Check │                                                       │
  └──────┬──────┘                                                       │
         │ pass                                                         │
         ▼                                                              │
  ┌─────────────┐                                                       │
  │  Push to    │                                                       │
  │    ECR      │                                                       │
  └──────┬──────┘                                                       │
         │                                                              │
         ▼                                                              │
  ┌─────────────┐     fail + rollback                                  │
  │  Deploy to  │──────────► ⏪ Rollback to previous task def          │
  │   Staging   │                                                       │
  │Health Check │                                                       │
  └──────┬──────┘                                                       │
         │ pass (PR merged to main) ◄────────────────────────────────┘
         ▼
  ┌─────────────┐
  │   Manual    │
  │  Approval   │◄── Reviewer approves in GitHub
  └──────┬──────┘
         │ approved
         ▼
  ┌─────────────┐     fail + rollback
  │  Deploy to  │──────────► ⏪ Rollback to previous task def
  │  Production │
  │Health Check │
  └──────┬──────┘
         │ pass
         ▼
       ✅ Done
```

---

## Infrastructure Components

| Component | Dev | Staging | Prod |
|---|---|---|---|
| VPC CIDR | `10.0.0.0/16` | `10.1.0.0/16` | `10.2.0.0/16` |
| ECS Tasks (min/max) | 2 / 2 | 2 / 4 | 2 / 6 |
| Task CPU | 256 | 512 | 1024 |
| Task Memory | 512 MB | 1024 MB | 2048 MB |
| ALB | ✅ | ✅ | ✅ |
| ECR | ✅ | ✅ | ✅ |
| CloudWatch | ✅ | ✅ | ✅ |
| Auto Scaling | ✅ | ✅ | ✅ |

---

## Setup Instructions

### Prerequisites
- AWS CLI installed and configured
- Terraform >= 1.3.0
- Docker installed
- GitHub repository with Actions enabled

### Step 1 — Configure AWS credentials
```bash
aws configure
# Enter Access Key ID, Secret Access Key, region: ap-south-1
```

### Step 2 — Bootstrap remote state (run once)
```bash
chmod +x bootstrap.sh
./bootstrap.sh
```
This creates:
- S3 bucket: `infra-pipeline-terraform-state` (versioned + encrypted)
- DynamoDB table: `infra-pipeline-terraform-locks` (for state locking)

### Step 3 — Configure GitHub Secrets
Go to `GitHub → Repository → Settings → Secrets and Variables → Actions`

Add the following secrets:

| Secret Name | Value |
|---|---|
| `AWS_ACCESS_KEY_ID` | Your AWS Access Key ID |
| `AWS_SECRET_ACCESS_KEY` | Your AWS Secret Access Key |

### Step 4 — Initialize Terraform for each environment
```bash
cd terraform/envs/dev
terraform init
terraform validate
terraform plan -var-file=terraform.tfvars

cd ../staging
terraform init

cd ../prod
terraform init
```

### Step 5 — Deploy via pipeline
```bash
# Create a feature branch
git checkout -b feature/my-change

# Make changes, commit and push
git add .
git commit -m "feat: describe your change"
git push origin feature/my-change

# Open a Pull Request → triggers staging deployment
# Merge to main → triggers production deployment (with approval)
```

### Step 6 — Manual deploy (if needed)
```bash
cd terraform/envs/staging
terraform apply -var-file=terraform.tfvars -var="container_image=<ecr-image-uri>"
```

---

## Runbook — Common Failure Scenarios

### 1. Pipeline fails at `terraform validate`
**Symptom:** Lint job fails with syntax error
**Fix:**
```bash
cd terraform/envs/dev
terraform init -backend=false
terraform validate
# Fix the reported error in the .tf file
```

### 2. Docker build fails
**Symptom:** Build job fails — image won't build
**Fix:**
```bash
cd apps
docker build -t test-app .
docker run -p 3000:3000 test-app
curl http://localhost:3000/health
# Fix Dockerfile or app code
```

### 3. ECS tasks not starting — health check failing
**Symptom:** Deploy job fails, health check returns non-200
**Steps:**
```bash
# Check ECS service events
aws ecs describe-services \
  --cluster infra-pipeline-staging-cluster \
  --services infra-pipeline-staging-service \
  --region ap-south-1

# Check CloudWatch logs
aws logs tail /ecs/infra-pipeline-staging --follow
```
**Common causes:**
- Wrong container image URI
- App crashing on startup — check logs
- Health check path wrong — verify `/health` returns 200

### 4. Rollback triggered automatically
**Symptom:** Pipeline rolls back to previous task definition
**What happened:** Health check failed 10 times over 5 minutes post-deploy
**Verify rollback succeeded:**
```bash
aws ecs describe-services \
  --cluster infra-pipeline-staging-cluster \
  --services infra-pipeline-staging-service \
  --query 'services[0].taskDefinition'
```
**Fix:** Check logs, fix the issue, push a new commit

### 5. `terraform init` fails — S3 bucket not found
**Symptom:** Backend initialization error
**Fix:**
```bash
# Re-run bootstrap script
./bootstrap.sh
# Then retry terraform init
```

### 6. ECR push fails — not authenticated
**Symptom:** Push job fails with authentication error
**Fix:**
```bash
aws ecr get-login-password --region ap-south-1 | \
  docker login --username AWS --password-stdin \
  <account-id>.dkr.ecr.ap-south-1.amazonaws.com
```

### 7. ECS service stuck in DRAINING
**Fix:**
```bash
aws ecs update-service \
  --cluster infra-pipeline-staging-cluster \
  --service infra-pipeline-staging-service \
  --desired-count 0 \
  --region ap-south-1

aws ecs delete-service \
  --cluster infra-pipeline-staging-cluster \
  --service infra-pipeline-staging-service \
  --force \
  --region ap-south-1
```

---

## Estimated Monthly AWS Costs

### Dev Environment
| Resource | Spec | Cost/month |
|---|---|---|
| ECS Fargate | 2 tasks × 0.25 vCPU × 0.5 GB | ~$8 |
| ALB | 1 ALB | ~$16 |
| NAT Gateway | 1 NAT | ~$32 |
| ECR | 1 repo ~1 GB | ~$0.10 |
| CloudWatch | Logs + alarms | ~$2 |
| **Total Dev** | | **~$58/month** |

### Staging Environment
| Resource | Spec | Cost/month |
|---|---|---|
| ECS Fargate | 2 tasks × 0.5 vCPU × 1 GB | ~$16 |
| ALB | 1 ALB | ~$16 |
| NAT Gateway | 1 NAT | ~$32 |
| ECR | 1 repo | ~$0.10 |
| CloudWatch | Logs + alarms | ~$2 |
| **Total Staging** | | **~$66/month** |

### Production Environment
| Resource | Spec | Cost/month |
|---|---|---|
| ECS Fargate | 2-6 tasks × 1 vCPU × 2 GB | ~$50-150 |
| ALB | 1 ALB | ~$16 |
| NAT Gateway | 1 NAT | ~$32 |
| ECR | 1 repo | ~$0.10 |
| CloudWatch | Logs + alarms + dashboard | ~$5 |
| **Total Prod** | | **~$103-203/month** |

### Total Estimated Cost
| Environment | Monthly Cost |
|---|---|
| Dev | ~$58 |
| Staging | ~$66 |
| Production | ~$103-203 |
| **Grand Total** | **~$227-327/month** |

> Use [AWS Pricing Calculator](https://calculator.aws) for exact estimates based on your usage.

---

## Security

- All secrets managed via GitHub Secrets — never in code
- ECS tasks run in private subnets — not directly accessible from internet
- ALB is the only public entry point
- ECR image scanning enabled on push
- S3 state bucket encrypted with AES256 and versioned
- DynamoDB locking prevents concurrent state modifications

---

## Repository Structure

```
infra-as-code-pipeline/
├── .github/
│   └── workflows/
│       └── ci-cd.yml          # GitHub Actions pipeline
├── apps/
│   ├── src/
│   │   └── index.js           # Node.js app with /health endpoint
│   └── Dockerfile             # Container definition
├── terraform/
│   ├── envs/
│   │   ├── dev/               # Dev environment config
│   │   ├── staging/           # Staging environment config
│   │   └── prod/              # Production environment config
│   └── modules/
│       ├── networking/        # VPC, subnets, IGW, NAT
│       ├── compute/           # ECS, ALB, ECR, autoscaling
│       ├── security/          # Security groups
│       └── monitoring/        # CloudWatch alarms, dashboard
├── bootstrap.sh               # Creates S3 + DynamoDB for remote state
├── .gitignore
└── README.md
```
