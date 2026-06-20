aws_region = "ap-northeast-1"

# Please use proper subnet ID and VPC ID
vpc_id = "vpc-0123456789abcdef0"
subnet_ids = [
  "subnet-0123456789abcdef1",
  "subnet-0123456789abcdef2",
  "subnet-0123456789abcdef3"
]

# EKS Sizing
cluster_version     = "1.36" # Latest k8s version for preprod - allow testing
node_min_size       = 2
node_max_size       = 4
node_desired_size   = 2
node_instance_types = ["t3.medium"]

environment = "preprod"