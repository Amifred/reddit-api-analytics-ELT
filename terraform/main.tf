terraform {
    required_version = ">= 1.4.2"

    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 4.16"
        }
    }
}

// Configure AWS provider
provider "aws" {
    region = var.aws_region // specify the AWS region to use
}

// Configure redshift cluster. 
resource "aws_redshift_cluster" "redshift" {
    cluster_identifier      = "redshift-cluster-pipeline"
    skip_final_snapshot     = true
    master_username         = "awsuser"
    master_password         = var.db_password
    node_type               = "dc2.large"
    cluster_type            = "single-node"
    publicly_accessible     = true
    iam_roles               = [aws_iam_role.redshift_role.arn]
    vpc_security_group_ids  = [aws_security_group.sg_redshift.id]
}

// Configure security group for Redshift allowing all inbound/outbound traffic
resource "aws_security_group" "sg_redshift" {
    name = "sg_redshift"
    ingress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

// Create IAM role with read-only access to S3
resource "aws_iam_role" "redshift_role" {
    name                = "RedShiftLoadRole"
    managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"]
    assume_role_policy  = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action    = "sts:AssumeRole"
                Effect    = "Allow"
                Principal = { Service = "redshift.amazonaws.com" }
            },
        ]
    })
}

// Create S3 bucket
resource "aws_s3_bucket" "redditapi_bucket" {
    bucket        = var.s3_bucket
    force_destroy = true
}

// Optionally, configure the S3 bucket's public access block settings
resource "aws_s3_bucket_public_access_block" "redditapi_bucket_public_access" {
    bucket                  = aws_s3_bucket.redditapi_bucket.id
    block_public_acls       = false
    block_public_policy     = false
    ignore_public_acls      = false
    restrict_public_buckets = false
}
