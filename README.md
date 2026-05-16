# Quick Start Guide: Illumina DRAGEN on AWS Batch

## Table of Contents

- [Quick Start Guide: Illumina DRAGEN on AWS Batch](#quick-start-guide-illumina-dragen-on-aws-batch)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
    - [Key Features](#key-features)
  - [Configuration Guidelines](#configuration-guidelines)
    - [VPC Setup](#vpc-setup)
    - [Batch Environment Setup](#batch-environment-setup)
    - [Deploy with Existing VPC](#deploy-with-existing-vpc)
  - [Stack Deployment Instructions](#stack-deployment-instructions)
  - [Post-Deployment Steps](#post-deployment-steps)
  - [Using DRAGEN with Nextflow](#using-dragen-with-nextflow)

## Overview

This is the SPENCERLAB guide for deploying the Illumina DRAGEN (Dynamic Read Analysis for GENomics) platform on AWS Batch. 

### Key Features

- High-performance DRAGEN environment hosted on AWS Batch
- Supports deployment in a **new** or **existing** AWS VPC

## Configuration Guidelines

These options represent baseline recommendations and should be tailored to suit your deployment strategy.

### VPC Setup (Note: do not modify this section)

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
- `LibDragenSO`: Path to the DRAGEN shared object (`.so`) file (this may need to be identified by launching the AMI and looking for /usr/lib64/libdragen.so.X-Y-Z)

### Deploy with Existing VPC

In `dragen.template.yaml`, define the following:

- `AMI`: ID of the DRAGEN Amazon Machine Image (get this by contacting Illumina and having them share the AMI with you.)
- `QSS3BucketName`: S3 bucket hosting Quick Start templates (For Spencerlab this is: dragen-aws-batch-quickstart)
- `QSS3BucketRegion`: Region where the S3 bucket resides
- `QSS3KeyPrefix`: Path prefix to template files in the bucket (For Spencerlab this is also: dragen-aws-batch-quickstart)
- `GenomicsS3Bucket`: Destination S3 bucket for DRAGEN output (For Spencer lab this is: dhslab-dragen-data)

## Stack Deployment Instructions

1. Open the AWS Console
2. In S3, create `QSS3BucketName` and `GenomicsS3Bucket`.
3. Upload the entire 'quickstart' repository to your S3 bucket location (from above):
   - `<QSS3BucketName>/<QSS3KeyPrefix>`
4. Go to CloudFormation and select "Create stack", choose "With new resources (standard)".
5. In the "Specify template: section, paste in the dragen template (https://`QSS3BucketName`.s3.us-east-1.amazonaws.com/`QSS3BucketName`/templates/dragen.template.yaml) and click `Next`.
6. Complete the required fields then click next:
   - Stack name
   - Network Configuration
      - VPC ID (select a VPC. If there is already one for Dragen, you can use this one.)
      - Private Subnet 1 ID (Same as above, you can select a subnet that's already named for Dragen)
      - Private Subnet 2 ID (Same as above, you can select a subnet that's already named for Dragen)
   - Key Pair
   - Genomics Data S3 Bucket (should already be filled)
   - Quick Start Bucket Name (should already be filled)
   - Quick Start Region (should already be filled)
   - Quick Start Key Prefix (should already be filled)
8. Confirm permissions and required capabilities (IAM, etc.) then click next.
9. Review settings, and then click **Submit** to create the stack

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
