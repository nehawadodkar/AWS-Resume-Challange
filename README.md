# Cherry Blossom Webpage.

This project is inspired by the Cloud Resume Challenge, but instead of creating an online resume, I've developed a webpage that showcases information about the Cherry Blossom Festival in Washington, DC.

## Concepts Implemented

1. **HTML/CSS**: The webpage is built using HTML and styled with CSS.
2. **Static Website**: The site is hosted on Amazon S3.
3. **HTTPS/DNS**: Secured via CloudFront with DNS managed by Route 53.
4. **JavaScript**: Integrated a visitor counter using JavaScript.
5. **Database**: Uses DynamoDB to store visitor count data.
6. **API**: Lambda function backend for updating the visitor counter, using Lambda Function URLs.
7. **Node.js**: Backend logic is written in Node.js within the Lambda function.
8. **Infrastructure as Code (IaC)**: The infrastructure is managed using Terraform, with a remote backend stored in an S3 bucket.
9. **CI/CD**: GitHub Actions automate Terraform infrastructure provisioning and updates to the front-end S3 bucket.

## Code Structure

### Website HTML Code
- Located in `/CherryBlossom/`, this folder contains the necessary HTML, images, CSS, and JavaScript for the webpage. These files are uploaded to the S3 bucket.

### Terraform Code
All Terraform code can be executed either through the CI/CD workflows (recommended) or manually on your local machine. To run Terraform locally, you'll need to create a terraform.tf file and provide the necessary inputs.


#### Project Backend Creation using Terraform - `/infra/back-end.tf`
This Terraform configuration sets up the backend infrastructure for the static website, which includes:
- **AWS Lambda Function**: Tracks website visitors and updates the visitor count in a DynamoDB table.
- **IAM Role and Policy**: Grants Lambda permissions to log data and modify the visitor count.
- **Lambda Function URL**: Makes the function accessible from the website hosted on S3.
- **DynamoDB Table**: Stores the visitor count.
- **Config.js in S3**: Stores the function URL for frontend use.
Terraform automates the setup of these resources, ensuring all AWS services work seamlessly together.

#### Project Front-End Setup using Terraform - `/infra/front-end.tf`
This Terraform configuration sets up the front-end infrastructure for the static website, including:
- **S3 Bucket**: Stores website files and blocks public access for security.
- **CloudFront Distribution**: Configured for efficient content delivery with caching rules and HTTPS support.
- **S3 Bucket Policy**: Allows CloudFront to securely retrieve objects.
- **Origin Access Control (OAC)**: Restricts direct S3 access, ensuring content is served only via CloudFront.
- **Route 53 DNS Record**: Maps a custom domain to the CloudFront distribution for user-friendly access.

## CI/CD Workflows

### Front-End S3 Bucket Update Workflow - `/github/workflows/front-end-cicd.yml`
This GitHub Actions workflow automates the process of updating the S3 bucket whenever changes are made to the website files in the `CherryBlossom/` folder. The workflow triggers in two cases:
- **Manual Execution** (via `workflow_dispatch`).
- **Push to the main branch**.
The workflow syncs updated files to the S3 bucket using `aws s3 sync` and invalidates the CloudFront cache to ensure visitors see the latest content immediately. If no CloudFront distribution is found, the workflow exits gracefully without failing.

### Infrastructure Preview - Terraform Plan Workflow - `/github/workflows/infra-preview.yml`
This workflow automates the Terraform plan process to preview infrastructure changes before applying them. It triggers:
- **Manually** (via `workflow_dispatch`).
- **When a pull request is opened, updated, or reopened** for files in the `infra/` directory.
The workflow runs `terraform plan` to generate a preview of infrastructure changes, helping validate updates before deployment.

### Infrastructure Update - Terraform Apply Workflow - `/github/workflows/infra-update.yml`
This GitHub Actions workflow automates the Terraform apply process to provision and update infrastructure. It triggers:
- **Manually** (via `workflow_dispatch`).
- **On a push to the main branch** when changes are made in the `infra/` directory or workflow files.
The workflow runs `terraform plan` to preview changes and then executes `terraform apply -auto-approve` to automatically apply the infrastructure changes.

### Infrastructure Destroy - Terraform Destroy Workflow - `/github/workflows/infra-update.yml`
This workflow automates the Terraform destroy process to tear down infrastructure. It is triggered **only manually** via `workflow_dispatch`, ensuring destruction is intentional. The workflow runs `terraform destroy -auto-approve`, which removes all deployed resources without requiring manual confirmation.

## Inputs Required

### Repo-Level Variables:
- **ALTERNATE_DOMAIN_NAME**: Custom domain name for the website.
- **DYNAMO_DB_TABLE_NAME**: Name of the DynamoDB table storing the visitor count.
- **LAMBDA_FUNCTION_NAME**: Name of the Lambda function.
- **S3_BUCKET_NAME**: Name of the S3 bucket hosting the website.

### Repo-Level Secrets:
- **AWS_ACCESS_KEY_ID**: AWS Access Key ID for authentication.
- **AWS_SECRET_ACCESS_KEY**: AWS Secret Access Key for authentication.
