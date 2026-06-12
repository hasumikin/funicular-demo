# Deployment

This demo app is deployed by creating a small AWS environment with CloudFormation, then using Kamal to push a Docker image to ECR and run it on EC2.

The deployed container runs with `RAILS_ENV=development` by default. This is intentional for the demo app.

## What Gets Created

- ECR repository: `rails-chat`
- EC2 instance: Ubuntu 22.04, default `t2.micro`
- Security group: inbound `22`, `80`, `443`
- Elastic IP
- Route53 A record: `rails-chat.hasumikin.com`
- Docker volume: `rails_chat_storage` mounted at `/rails/storage`

SQLite and Active Storage files live under `/rails/storage`, so they survive container replacements.
The container runs `bin/rails db:prepare` before Puma starts, so the development SQLite database is created automatically on first boot.
Docker health checks only verify that Puma is accepting TCP connections on port 80. Rails errors are inspected with `kamal logs`.
Development host authorization allows the public demo host and Docker container hostnames used by Kamal proxy checks.

## Prerequisites

Install and configure:

```bash
aws --version
kamal version
aws sts get-caller-identity
```

Install Kamal if needed:

```bash
gem install kamal
```

Prepare the EC2 SSH key:

```bash
chmod 600 ~/.ssh/YOUR_KEY.pem
```

You will need:

- AWS region, default `ap-northeast-1`
- EC2 Key Pair name
- Route53 Hosted Zone ID
- VPC ID
- public subnet ID
- SSH private key path

## Initial Setup

Run the setup helper:

```bash
bin/deploy_setup
```

The script creates the CloudFormation stack, waits for it to complete, then creates or updates:

- `config/deploy.yml`
- `.kamal/secrets`

Review the generated values:

```bash
sed -n '1,120p' config/deploy.yml
```

Do not commit `.kamal/secrets` or `config/deploy.yml`.

This demo deployment does not require `config/master.key`; no encrypted Rails credentials are used by default.
Rails still signs/encrypts session cookies, but in development Rails can generate `secret_key_base` automatically. If that generated value changes after a container rebuild or redeploy, existing login sessions may be invalidated and users may need to log in again. That is acceptable for this demo app.

## Deploy

First deployment:

```bash
kamal setup
```

Later deployments:

```bash
kamal deploy
```

Logs:

```bash
kamal logs
```

Rails console:

```bash
kamal console
```

Shell:

```bash
kamal shell
```

Seed demo data if needed:

```bash
kamal app exec --interactive --reuse "bin/rails db:seed"
```

## Check Status

CloudFormation status and outputs:

```bash
bin/rails infra:status
```

DNS:

```bash
dig rails-chat.hasumikin.com
```

## Update Infrastructure

After changing `infrastructure/cloudformation.yml`:

```bash
bin/rails infra:update
```

Validate the template:

```bash
bin/rails infra:validate
```

## Delete Infrastructure

To delete the stack and ECR images:

```bash
bin/rails infra:delete
```

The task requires typing `DELETE` to confirm.

## Troubleshooting

### `config/deploy.yml` does not exist

Run:

```bash
bin/deploy_setup
```

### ECR login fails

Check the active AWS account and region:

```bash
aws sts get-caller-identity
aws ecr get-login-password --region ap-northeast-1
```

### SSH to EC2 fails

Check that:

- the EC2 Key Pair name is correct
- the private key path in `config/deploy.yml` is correct
- the private key has permission `600`
- port `22` is open in the security group
- `ssh.user` is `ubuntu`

### HTTPS does not work

Check that:

- the Route53 A record points to the Elastic IP
- `proxy.host` in `config/deploy.yml` is `rails-chat.hasumikin.com`
- ports `80` and `443` are open
- DNS propagation has completed
