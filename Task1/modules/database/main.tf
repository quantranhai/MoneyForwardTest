# Variables 
variable environment {}
variable availability_zone {}
variable db_instance_class {
  default = "db.t2.micro"
}

# Resources
resource "aws_rds_cluster" "rds" {
  cluster_identifier      = "${var.environment}-aurora-cluster"
  availability_zones      = ["${var.availability_zone}"]
  database_name           = "myappdb"
  master_username         = "master"
  master_password         = "Passw0rd"
  backup_retention_period = 5
  preferred_backup_window = "01:00-03:00"
}

resource "aws_rds_cluster_instance" "rds_instance_1" {
  cluster_identifier = aws_rds_cluster.rds.id
  identifier         = "${var.environment}rds1"
  instance_class     = "${var.db_instance_class}"
  engine             = aws_rds_cluster.rds.engine
  engine_version     = aws_rds_cluster.rds.engine_version
}

resource "aws_rds_cluster_instance" "rds_instance_2" {
  cluster_identifier = aws_rds_cluster.rds.id
  identifier         = "${var.environment}rds2"
  instance_class     = "${var.db_instance_class}"
  engine             = aws_rds_cluster.rds.engine
  engine_version     = aws_rds_cluster.rds.engine_version
}
