# ecs-rpc-service - A highly-available ethereum node service for Amazon Elastic Container Service

![Architectural diagram](https://github.com/blockscale/ecs-rpc-service/raw/master/doc/images/architectural_diagram.png "Architectural diagram")

## Installation instructions
1. Place a copy of your parity .local directory with a completely up-to-date blockchain in an S3 bucket by using the
   `aws s3 sync` command
2. Install the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html).
3. Set environment variables like AWS_DEFAULT_REGION and AWS_PROFILE to the settings you prefer.
4. Create a key pair under **EC2 > Key pairs** in your preferred region in the AWS Management Console and save the
   private key (PEM file) to your workstation so you can ssh to the instances in your ECS cluster.
5. `cp config/params.example.json config/params.json`
6. Edit `config/params.json` for your own VPC, subnets, etc.
7. Install ruby on your OS if it's not there already. You may wish to use an environment manager such as
   [RVM](https://rvm.io/) or [rbenv](https://github.com/rbenv/rbenv) to avoid polluting your global ruby environment.
8. Once in your ruby environment:
   1. `gem install bundler`
   2. `bundle install`
   3. `rake`