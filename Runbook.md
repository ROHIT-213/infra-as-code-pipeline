##1. System Overview
This system provides an automated, zero-downtime deployment pipeline for a Node.js application running on AWS ECS Fargate. The infrastructure is managed via Terraform and deployed via GitHub Actions.

   
##A. Deploying a New Version

  1. Ensure all code changes are merged into the main branch.
  2. The pipeline will trigger automatically.
  3. Navigate to the GitHub Actions tab to monitor progress.
  4. If the Approval stage is reached, a lead engineer must manually approve the deployment to Production.
     
##B. Manual Infrastructure Scaling
If you need to scale the application (e.g., during high traffic):
  1. Navigate to terraform/envs/prod/terraform.tfvars
  2. Adjust the app_count variable (e.g., from 2 to 5).
  3. Commit and push. Terraform will handle the rolling update.

##3. Troubleshooting & Incident Response
##C. Handling Deployment Failures (Automated Rollback)
The pipeline includes an Atomic Rollback mechanism.
- Symptom: The deploy-prod job fails at the Health Check step.
- Automated Action: The pipeline automatically detects the 500 error or timeout and runs aws ecs update-service to revert to the previous Task Definition.
- Verification: Check the ECS Service "Events" tab in the AWS Console to confirm the service has stabilized with the previous revision.

##D. Error: "TaskDefinition is inactive" during Rollback
- Cause: The fallback revision was deregistered or deleted.
- Resolution:
    1. Go to ECS Console > Task Definitions.
    2. Filter by Inactive.
    3. Select the required revision (e.g., Rev 20).
    4. Click Actions > Reactivate.
    5. Re-run the GitHub Action job.
##E. Error: "403 Rate Limit Exceeded" (TFLint)
- Cause: GitHub API rate limits hit during Terraform linting.
- Resolution: Ensure the GITHUB_TOKEN is correctly mapped in the ci-cd.yml file under the env section for the TFLint step.

##4. Maintenance Tasks
Task                              Frequency          Responsibility
--------------------------------------------------------------------------------------------
Terraform State Cleanup           Monthly              DevOps Engineer
--------------------------------------------------------------------------------------------
ECR Image Pruning                 Quaterly             Automate via ECR Lifecycle Policy
--------------------------------------------------------------------------------------------
AWS Secret Rotation               Every 90 Days        Security Lead
--------------------------------------------------------------------------------------------
##5. Deployment Architecture Reference
The following diagram illustrates the traffic flow and the components you are managing. Use this to trace connectivity issues between the ALB and ECS.

##6. Emergency Contacts
   - Primary Maintainer: ROHIT (Owner of ROHIT-213/infra-as-code-pipeline)
   - Cloud Provider: AWS (Support Tier: Basic/Developer)

