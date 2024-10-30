# POC: Deploy Redis Cluster Across Two Kubernetes Clusters
# Redis-DB Project

This is a POC on deploying a highly available (HA) Redis cluster across two Kubernetes clusters.

## Architecture

### 1. AWS-EKS

- **Kubernetes Clusters**: The project uses two Kubernetes clusters named `redis-1` and `redis-2`. Each cluster consists of 3 Kubernetes nodes, making a total of 6 nodes across both clusters.

### 2. Redis

- **Redis Cluster**: A single Redis cluster is deployed across the two Kubernetes clusters. Each Kubernetes cluster will have 3 Redis pods, resulting in a total of 6 Redis pods across both clusters (`redis-1` and `redis-2`).

## Pre-requisites

To deploy and manage the Redis cluster, you need the following credentials and configurations:

1. **AWS Credentials**:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `AWS_DEFAULT_REGION`

2. **Redis Cluster Configuration**:
  - **Password**: The default password for the Redis cluster is `bitnami`.
  - **Redis Cluster ID**: This ID is used to segregate multiple Redis clusters if deployed in the same Kubernetes cluster. The default ID is `abcd`.

3. **Cloudflare DNS Management**:
  - **API Key**: Used to manage DNS records.
  - **Zone ID**: Used to identify the DNS zone.

4. **Terraform**:
  - Ensure Terraform is installed and available in your PATH. You can install it from the [Terraform downloads page](https://www.terraform.io/downloads).

### Example DNS Records

The DNS records are automatically mapped/created using Cloudflare. Here are the example DNS records:

- `cluster1.redis1.abcd.404ops.in`
- `cluster1.redis2.abcd.404ops.in`
- `cluster1.redis3.abcd.404ops.in`
- `cluster2.redis1.abcd.404ops.in`
- `cluster2.redis2.abcd.404ops.in`
- `cluster2.redis3.abcd.404ops.in`
## Deploy

### 1. Manual (AWS Console)

1. **Create Two AWS EKS Clusters**:
  - Create two AWS EKS clusters named `redis-1` and `redis-2`. Each cluster should have 3 nodes of type minimum: T3-medium.

2. **Authenticate the Cluster**:
  - Authenticate the cluster `redis-1` by the command given below:
    ```sh
    aws eks update-kubeconfig --name redis-1
    ```

3. **Update Values in `values.yaml`**:
  - Update values in `values.yaml` of the Helm chart located at `./installer/installer/values.yaml` and install the Helm chart by command:
    ```sh
    helm install installer installer/installer
    ```

4. **Create Redis Cluster**:
  - Once your clusters are ready with Redis cross-cluster deployment, you can create a Redis cluster by command:
    ```sh
    redis-cli --cluster create FQDN-c1-n1:6379 FQDN-c1-n2:6379 FQDN-c1-n3:6379 FQDN-c2-n1:6379 FQDN-c2-n2:6379 FQDN-c2-n3:6379 --cluster-replicas 1
    ```

### 2. Using Terraform

1. **Verify Directory Structure**:
  - Ensure the `terraform/policy` directory exists. If not, navigate to the correct directory.

2. **Install Terraform**:
  - If Terraform is not installed, download and install it from the [Terraform downloads page](https://www.terraform.io/downloads).

3. **Initialize Terraform**:
  - Navigate to the directory containing the Terraform configuration files:
    ```sh
    cd path/to/terraform/policy
    terraform init
    ```

4. **Apply Terraform Configuration**:
  - Apply the Terraform configuration to set up the necessary AWS resources:
    ```sh
    terraform apply
    ```

### 3. Update `kubectl` Context for Each Cluster

1. **Update `kubectl` Context for `redis-1`**:
  ```sh
  aws eks --region us-east-1 update-kubeconfig --name redis-1
  ```

2. **Verify `kubectl` Context for `redis-1`**:
  ```sh
  kubectl config current-context
  kubectl get nodes
  ```

3. **Update `kubectl` Context for `redis-2`**:
  ```sh
  aws eks --region us-east-1 update-kubeconfig --name redis-2
  ```

4. **Verify `kubectl` Context for `redis-2`**:
  ```sh
  kubectl config current-context
  kubectl get nodes
  ```

### 4. Deploy the Job to the Cluster

1. **Deploy the Redis Cluster Using Helm**:
  - Once the kubectl context is set correctly, we can deploy the Redis cluster using Helm. This step involves using the values.yaml file to configure the Helm chart.
  - Deploy Redis Cluster:
  ```sh
  helm install redis-cluster . -f values.yaml
  ```

1. **Deploy `job.yaml`**:
  - Ensure that your `kubectl` context is set to the correct cluster (e.g., `redis-1` or `redis-2`).
  - Apply the `job.yaml` file to create the job in the cluster:
  ```sh
  kubectl apply -f job.yaml
  ```

### Example Commands

1. **Update `kubectl` Context for `redis-1`**:
  ```sh
  aws eks --region us-east-1 update-kubeconfig --name redis-1
  ```

2. **Verify `kubectl` Context for `redis-1`**:
  ```sh
  kubectl config current-context
  kubectl get nodes
  ```

3. **Update `kubectl` Context for `redis-2`**:
  ```sh
  aws eks --region us-east-1 update-kubeconfig --name redis-2
  ```

4. **Verify `kubectl` Context for `redis-2`**:
  ```sh
  kubectl config current-context
  kubectl get nodes
  ```

5. **Deploy `job.yaml`**:
  ```sh
  kubectl apply -f job.yaml
  ```

### Summary

By updating your `kubectl` context to point to each of the EKS clusters (`redis-1` and `redis-2`), you can manage and deploy resources to these clusters. Once the context is set correctly, you can deploy the necessary resources using `kubectl apply -f job.yaml`.

## Testing the Deployment

1. **Access Redis Pods**:
  - Use the DNS records to access the Redis pods. For example:
    ```sh
    redis-cli -h cluster1.redis1.abcd.404ops.in -a bitnami
    ```

2. **Verify High Availability**:
  - Test the high availability by shutting down nodes or clusters and verifying that the Redis cluster remains available.

## Summary

The Redis-DB project demonstrates how to deploy a highly available Redis cluster across two Kubernetes clusters using AWS EKS and Cloudflare DNS management. By following the steps outlined above, you can set up, deploy, and test the Redis cluster.