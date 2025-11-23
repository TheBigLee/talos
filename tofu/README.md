# Talos Terraform Configuration

This Terraform configuration provisions Talos control plane servers on Hetzner Cloud.

## Prerequisites

1. Install SOPS and age
2. Have a Hetzner Cloud API token
3. Install Terraform/OpenTofu

## Setup

1. Edit the `secrets.sops.yaml` file with your Hetzner Cloud token:
   ```bash
   sops secrets.sops.yaml
   ```
   Replace the `hcloud_token` value with your actual token.

2. Initialize Terraform:
   ```bash
   tofu init
   ```

3. Plan the deployment:
   ```bash
   tofu plan
   ```

4. Apply the configuration:
   ```bash
   tofu apply
   ```

## What gets created

- 3 control plane servers distributed across different locations
- A private network (10.0.0.0/16) for internal communication
- A load balancer exposing:
  - Kubernetes API (port 6443)
  - Talos API (port 50000)
- Proper server labeling for load balancer targeting

## Outputs

The configuration provides outputs for:
- Control plane server details (IPs, IDs, etc.)
- Load balancer information
- Network details
- API endpoints

## Next Steps

After Terraform creates the infrastructure, use talhelper to bootstrap the Talos cluster using the server IPs from the Terraform outputs.