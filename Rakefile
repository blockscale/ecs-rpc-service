require 'active_support'
require 'active_support/core_ext/object/blank'
require 'json'
require 'pathname'
require 'colorize'
require 'open3'

def random_text(number)
  charset = Array('a'..'z')
  Array.new(number) { charset.sample }.join
end

def my_exec(cmd, halt_on_error: true, hide_output: false)
  puts "Executing: #{cmd}".white.bold
  stdout, stderr, status = Open3.capture3(cmd)
  print stdout unless hide_output
  if status.exitstatus != 0
    exit(status.exitstatus) if halt_on_error
    puts "Previous command reported error code #{status}" unless hide_output
  end
  {stdout: stdout, stderr: stderr, status: status}
end

class DependencyChecker
  attr_accessor :aws_env

  def initialize
    self.aws_env = {}
  end

  def parse_credentials
    result = my_exec('aws sts get-caller-identity', hide_output: true)
    if result[:status] == 0
      credentials = JSON.parse(result[:stdout])
      username = credentials['Arn'].split('user/')[1]
      self.aws_env[:account] = credentials['Account']
      self.aws_env[:username] = username
      print "Using AWS CLI as account #{aws_env[:account]}, user #{aws_env[:username]}. "
      puts "Set AWS_PROFILE to change this."
      sleep(3) # give user a chance to break
    else
      exit(1)
    end
  end

  def check_for_aws_cli
    cli_installed = my_exec('which aws')
    unless cli_installed.blank?
      region = ENV['AWS_DEFAULT_REGION']
      if region.blank?
        puts "Please set AWS_DEFAULT_REGION"
        exit(1)
      else
        self.aws_env[:region] = region
        parse_credentials
      end
    else
      puts "AWS CLI not installed. Please install to continue. Instructions here:"
      puts "https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html"
      exit(1)
    end
  end

  def check_for_docker
    docker_installed = `which docker`
    if docker_installed.blank?
      puts "Docker not installed. Please install docker."
      exit(1)
    end
  end
end

dc = DependencyChecker.new

desc "Check for dependencies"
task :confirm_can_build do
  dc.check_for_aws_cli
  dc.check_for_docker
end

task :build_rpc_docker do
  dockerdir = Pathname.new(__dir__).join('docker/parity/rpc')
  Dir.chdir(dockerdir)
  region = dc.aws_env[:region]
  my_exec("aws ecr create-repository --repository-name rpc", halt_on_error: false, hide_output: true)
  result = my_exec("aws ecr get-login --no-include-email", hide_output: true)
  my_exec result[:stdout]
  my_exec 'docker build -t rpc .'
  acct = dc.aws_env[:account]
  my_exec "docker tag rpc:latest #{acct}.dkr.ecr.#{region}.amazonaws.com/rpc:latest"
  my_exec "docker push #{acct}.dkr.ecr.#{region}.amazonaws.com/rpc:latest"
end

task :build_updater_docker do
  dockerdir = Pathname.new(__dir__).join('docker/parity/updater')
  Dir.chdir(dockerdir)
  region = dc.aws_env[:region]
  my_exec("aws ecr create-repository --repository-name updater", halt_on_error: false, hide_output: true)
  result = my_exec("aws ecr get-login --no-include-email", hide_output: true)
  my_exec result[:stdout]
  my_exec 'docker build -t updater .'
  acct = dc.aws_env[:account]
  my_exec "docker tag updater:latest #{acct}.dkr.ecr.#{region}.amazonaws.com/updater:latest"
  my_exec "docker push #{acct}.dkr.ecr.#{region}.amazonaws.com/updater:latest"
end

desc "Build docker images"
task :docker => [:confirm_can_build, :build_rpc_docker, :build_updater_docker] do
end

desc "Generate unique bucket prefix"
task :generate_unique_prefix => :confirm_can_build do
  suffix = random_text(20)
  my_exec("aws ssm put-parameter --name '/EcsRpcService/suffix' --type 'String' --value '#{suffix}' --no-overwrite", halt_on_error: false, hide_output: true)
end

desc "Create S3 bucket for CloudFormation templates"
task :create_template_bucket => [:generate_unique_prefix] do
  result = my_exec("aws ssm get-parameter --name '/EcsRpcService/suffix'", hide_output: true)
  h = JSON.parse(result[:stdout])
  dc.aws_env[:suffix] = h['Parameter']['Value']
  my_exec("aws s3 mb s3://ecs-rpc-service-templates-#{dc.aws_env[:suffix]}", halt_on_error: false, hide_output: true)
end

desc "Push CloudFormation updates"
task :push_cfn_templates => [:create_template_bucket] do
  my_exec("aws s3 cp templates s3://ecs-rpc-service-templates-#{dc.aws_env[:suffix]} --recursive", halt_on_error: false)
end

task :default => [:docker]
