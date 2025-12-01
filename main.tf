# Network Module - Creates VPC, Subnets, Gateways, and Security Groups
module "network" {
  source = "./modules/network"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  enable_nat_gateway   = true
  enable_vpn_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Project   = "Examen Redes de Computadores"
    Owner     = "Estudiante"
    Course    = "Redes"
  }
}

# Compute Module - Creates Web Servers, API, Database
module "compute" {
  source = "./modules/compute"

  project_name           = var.project_name
  environment            = var.environment
  vpc_id                 = module.network.vpc_id
  public_subnet_ids      = module.network.public_subnet_ids
  private_subnet_ids     = module.network.private_subnet_ids
  web_security_group_id  = module.network.web_security_group_id
  app_security_group_id  = module.network.app_security_group_id
  db_security_group_id   = module.network.db_security_group_id
  
  instance_type_web = "t2.micro"
  instance_type_app = "t2.micro"
  instance_type_db  = "t2.micro"
  
  # key_name = "your-key-pair-name"  # Descomenta y agrega tu key pair

  tags = {
    Project   = "Examen Redes de Computadores"
    Owner     = "Estudiante"
    Course    = "Redes"
  }
}
