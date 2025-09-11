# Quick Start Guide: Illumina DRAGEN on AWS Batch

## Table of Contents

- [Overview](#overview)
- [Configuration Guidelines](#configuration-guidelines)
  - [VPC Setup](#vpc-setup)
  - [Batch Environment Setup](#batch-environment-setup)
  - [Deploy with New VPC](#deploy-with-new-vpc)
  - [Deploy with Existing VPC](#deploy-with-existing-vpc)
- [Stack Deployment Instructions](#stack-deployment-instructions)
- [Post-Deployment Steps](#post-deployment-steps)
- [Using DRAGEN with Nextflow](#using-dragen-with-nextflow)

## Overview

This guide explains how to deploy the Illumina DRAGEN (Dynamic Read Analysis for GENomics) platform on AWS Batch. DRAGEN provides lightning-fast, accurate analysis of next-generation sequencing (NGS) data using purpose-built hardware acceleration.

### Key Features

- High-performance DRAGEN environment hosted on AWS Batch
- Supports deployment in a **new** or **existing** AWS VPC

## Configuration Guidelines

These options represent baseline recommendations and should be tailored to suit your deployment strategy.

### VPC Setup

In `aws-vpc.template.yaml`, define CIDR values and subnet tags:

- Configure default public and private subnets
- To add more subnets, include parameters like:
  - `PublicSubnet<number>CIDR`
  - `PublicSubnetTag<number>`

### Batch Environment Setup

In `batch.template.yaml`, define these parameters:

- `GenomicsS3Bucket`: S3 bucket for genomic data storage
- `MaxvCpus`: Maximum vCPUs for compute environment
- `RetryNumber`: Retry count per AWS Batch job
- `DragenVersion`: DRAGEN software version
- `LibDragenSO`: Path to the DRAGEN shared object (`.so`) file

### Deploy with New VPC

In `dragen-main.template.yaml`, set values for:

- VPC CIDR block
- Public and private subnets
- Additional subnets as needed (e.g., `PublicSubnet2CIDR`)

### Deploy with Existing VPC

In `dragen.template.yaml`, define the following:

- `AMI`: ID of the DRAGEN Amazon Machine Image
- `QSS3BucketName`: S3 bucket hosting Quick Start templates
- `QSS3BucketRegion`: Region where the S3 bucket resides
- `QSS3KeyPrefix`: Path prefix to template files in the bucket
- `GenomicsS3Bucket`: Destination S3 bucket for DRAGEN output

## Stack Deployment Instructions

1. Open the AWS Console
2. Upload this repository to your S3 bucket using the with the following path structure:
   - `<QSS3BucketName>/<QSS3KeyPrefix>`
3. Create the `GenomicsS3Bucket` S3 bucket
4. Choose a deployment option:
   - **Existing VPC:** Use `dragen.template.yaml`
   - **New VPC:** Use `dragen-main.template.yaml`
5. Obtain the Amazon S3 URL of your chosen template
6. Navigate to the `CloudFormation` service and choose `Create Stack`
7. Use the above Amazon S3 URL for the template, and then update the following parameters if needed:
   - Stack name
   - Availability Zones
   - Key Pair
   - Genomics Data S3 Bucket
   - Quick Start Bucket Name
   - Quick Start Region
   - Quick Start Key Prefix
8. Confirm permissions and required capabilities (IAM, etc.)
9. Click **Next**, review settings, and then click **Submit** to create the stack

## Post-Deployment Steps

Once the stack is created, verify that the DRAGEN instance is configured properly by launching an EC2 instance from the **Launch Template** and running a **DRAGEN self-test** job.

> [!WARNING]
> If you modify the EC2 instance configuration, you must recreate the AWS Batch compute environment for changes to take effect.

## Using DRAGEN with Nextflow

To integrate DRAGEN AWS Batch into your Nextflow pipeline:

1. Set up AWS credentials and region in `nextflow.config`:

   ```nextflow
   aws {
       region    = 'us-east-1'
       accessKey = secrets.AWS_ACCESS_KEY
       secretKey = secrets.AWS_SECRET_KEY
   }
   ```

2. Configure the job executor and queue for a profile (e.g., `dragen-on-aws`) and process label (e.g., `dragen`):

   ```nextflow
   dragen-on-aws {
       process {
           withLabel: dragen {
               executor = 'awsbatch'
               queue    = '<dragen-queue-name>'
           }
       }
   }
   ```

3. Specify the container using the DRAGEN job definition and revision number:

   > [!INFO]
   > Use the following format: `job-definition://<job-definition-name>:<revision-number>`

   Example:

   ```nextflow
   container 'job-definition://dragen_<dragen version>:1'
   ```
