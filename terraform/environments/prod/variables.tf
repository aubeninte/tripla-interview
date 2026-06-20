variable "aws_region" {
  type        = string
  description = "The target AWS region for deployment"
}

variable "cluster_version" {
  type        = string
  description = "The Kubernetes version for the EKS cluster"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the target VPC"
}

variable "subnet_ids" {
  type        = list(string)
  description = "The list of subnet IDs for EKS node and control plane placement"
}

# Node Group Sizing & Scaling Configurations
variable "node_min_size" {
  type        = number
  description = "Minimum number of worker nodes allowed in the EKS node group"
}

variable "node_max_size" {
  type        = number
  description = "Maximum number of worker nodes allowed in the EKS node group"
}

variable "node_desired_size" {
  type        = number
  description = "Initial desired number of worker nodes in the EKS node group"
}

variable "node_instance_types" {
  type        = list(string)
  description = "The AWS EC2 instance types for the worker nodes"
}

variable "environment" {
  type        = string
  description = "Envrionment in which the cluster is being created for"
}