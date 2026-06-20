variable "vpc_id" {
  type    = string
  default = ""
}

variable "subnet_ids" {
  type    = list(string)
  default = []
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "project_name" {
  type    = string
  default = "tripla-bucket"
}

variable "cluster_version" {
  type    = string
  default = "1.35"
}

variable "node_min_size" {
  type        = number
  description = "Minimum number of nodes in the managed node group"
  default     = 1
}

variable "node_max_size" {
  type        = number
  description = "Maximum number of nodes in the managed node group"
  default     = 3
}

variable "node_desired_size" {
  type        = number
  description = "Desired number of nodes in the managed node group"
  default     = 2
}

variable "node_instance_types" {
  type        = list(string)
  description = "List of instance types associated with the EKS Node Group"
  default     = ["t3.medium"]
}