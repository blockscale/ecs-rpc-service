# ecs-rpc-service - A highly-available ethereum node service for Amazon Elastic Container Service

![Architectural diagram](https://github.com/blockscale/ecs-rpc-service/raw/master/doc/images/architectural_diagram.png "Architectural diagram")

## Pre-installation

This solution requires bootstrapping with an existing copy of a full parity node's blockchain state. To do this, we
recommend installing parity on an EC2 i3.large instance, waiting several days for it to sync, and then copying the
contents of the parity .local directory to an S3 bucket in the same region. 

## Installation instructions

1.  Install the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html).
2.  Install [Docker](https://www.docker.com/).
3.  Set environment variables like AWS_DEFAULT_REGION and AWS_PROFILE to the settings you prefer.
4.  Create a key pair under **EC2 > Key pairs** in your preferred region in the AWS Management Console and save the
    private key (PEM file) to your workstation so you can ssh to the instances in your ECS cluster.
5.  `cp config/params.example.json config/params.json`
6.  Edit `config/params.json` for your own VPC, subnets, etc.
7.  Install ruby on your OS if it's not there already. You may wish to use an environment manager such as
    [RVM](https://rvm.io/) or [rbenv](https://github.com/rbenv/rbenv) to avoid polluting your global ruby environment.
8.  Once in your ruby environment:
    1. `gem install bundler`
    2. `bundle install`
    3. `rake`
9.  Given a node size of 150GB, the stack creation process takes about thirty minutes, and another thirty for the nodes
    to come fully online.
10. After creating the stack, the progress of the nodes downloading the blockchain can be tracked in **CloudWatch Logs**.
    The health of the cluster can be checked by going to **EC2 > Load Balancers > Target Groups**.
    
## Using the service    
    
Once the cluster nodes are healthy, it should be possible to send transactions to the RPC service. The RPC URI can be
found in **CloudFormation** under the main stack's outputs. Here is a test transaction that can be sent from the
command line. If the service is working, you should get a response like the one below.

```
∴ curl <URI> -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":67}'
{"jsonrpc":"2.0","result":"Parity-Ethereum//v2.5.8-stable-c52a6c8-20190916/x86_64-linux-gnu/rustc1.36.0","id":67}
```

## Future improvements

This deployment currently uses the parity Ethereum client. We plan to add support for geth and possibly Hyperledger Besu
in the future. Feel free to contact us with additional feature requests.