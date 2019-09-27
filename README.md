# ecs-rpc-service - A highly-available ethereum node service for Amazon Elastic Container Service

![Architectural diagram](https://github.com/blockscale/ecs-rpc-service/raw/master/doc/images/architectural_diagram.png "Architectural diagram")

## Installation instructions
1. Place a copy of your parity .local directory with a completely up-to-date
   blockchain in an S3 bucket by using the `aws s3 sync` command
2. Install the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html).
3. Set environment variables like AWS_DEFAULT_REGION and AWS_PROFILE to the
   settings you prefer.
4. Create a key pair under **EC2 > Key pairs** in your preferred region in the
   AWS Management Console and save the private key (PEM file) to your
   workstation so you can ssh to the instances in your ECS cluster.
5. Install ruby on your OS if it's not there already. You may wish to use an
   environment manager such as [RVM](https://rvm.io/) or
   [rbenv](https://github.com/rbenv/rbenv) to avoid polluting your global
   environment.
6. Once in your ruby environment:
   1. `gem install bundler`
   2. `bundle install`
   3. `rake`

### Launch the ECS Cluster
The following steps will allow you to launch the ECS cluster:
1. Open the CloudFormation console, and select Create stack.
2. Browse to the file *ecs-cluster.yaml* that is located in the root of the git repository.
3. Select the right instance type (only the i3 family is currently supported).
4. Select the amount of instances you would like to launch.
5. Assign a unique name to the environment and stack. I used "parity-ecs".
6. Select the subnets you would like to launch instances in.
  * I recommend you use the Default VPC in your AWS account, and select all subnets in the VPC.
7. Select the VPC that matches the subnets you chose earlier.
8. If you are using the Default VPC, you can keep the CIDR range as 172.31.0.0/16, but if you are using a different VPC, please modify the CIDR range to match your VPC.  The CloudFormation template creates a security group that allows JSON RPC traffic from this CIDR range, to prevent it from being reachable to the public Internet.
8. Wait until the CloudFormation stack is completely created before proceeding to the next step.

### Launch the Parity Service
The following steps will allow you to launch the Parity service that will run in the ECS cluster:
1. Open the CloudFormation console, and select Create stack.
2. Browse to the file *parity-service.yaml* that is located in the root of the git repository.
3. Select the right number of parity nodes you would like to run.  Current testing indicates the following ratios provide suitable performance:
  * i3.xlarge - 2 parity nodes per instance.
  * i3.2xlarge - 4 parity nodes per instance.
  * i3.4xlarge - 8 parity nodes per instance.
  * i3.8xlarge - 16 parity nodes per instance (and so on).
4. Modify the Docker registry location to point to the ECR registry you created earlier.
5. Select the same subnets and VPC that you selected when launching the ECS cluster.
6. Launch the CloudFormation stack.
7. Verify that all of the parity tasks have started properly, and watch CloudWatch logs to ensure that they are able to download the blockchain from S3.
  * After the blockchain is downloaded, and parity starts, verify that your load balancer has healthy targets in the target group through the EC2 console.

### Launch the Parity Updater Service
The following steps will allow you to launch the Parity updater service that keeps the stored blockchain copy in S3 up to date.
1. Open the CloudFormation console, and select Create stack.
2. Browse to the file *parity-updater.yaml* that is located in the root of the git repository.
3. Modify the Docker registry location to point to the ECR registry you created earlier.
4. Launch the CloudFormation stack.
5. After the task starts, watch the CloudWatch logs to ensure that it works properly and is able to do the following:
  1. Downloads the parity blockchain data from S3.
  2. Starts parity, and catches up to the current block.
  3. 30 minutes after parity starts, shuts down parity cleanly.
  4. Copies newly downloaded blocks back to the S3 bucket to update the stored blockchain.
