require 'active_support'
require 'active_support/core_ext/object/blank'
require 'json'
require 'pathname'
require 'colorize'
require 'open3'

def my_exec(cmd, halt_on_error: true, hide_output: false)
  puts "Executing: #{cmd}".white.bold
  stdout, stderr, status = Open3.capture3(cmd)
  print stdout unless hide_output
  if status != 0
    exit(status) if halt_on_error
    puts "Previous command reported error code #{status}" unless hide_output
  end
  {stdout: stdout, stderr: stderr, status: status}
end

class DependencyChecker
  attr_accessor :aws_credentials

  def parse_credentials
    result = my_exec('aws sts get-caller-identity', hide_output: true)
    if result[:status] == 0
      credentials = JSON.parse(result[:stdout])
      username = credentials['Arn'].split('user/')[1]
      self.aws_credentials = {account: credentials['Account'], username: username}
      print "Using AWS CLI as account #{aws_credentials[:account]}, user #{aws_credentials[:username]}. "
      puts "Set AWS_PROFILE to change this."
      sleep(3) # give user a chance to break
    else
      exit(1)
    end
  end

  def check_for_aws_cli
    cli_installed = my_exec('which aws')
    unless cli_installed.blank?
      if ENV['AWS_DEFAULT_REGION'].blank?
        puts "Please set AWS_DEFAULT_REGION to your preferred AWS region"
        exit(1)
      else
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
  region = ENV['AWS_DEFAULT_REGION']
  my_exec("aws ecr create-repository --repository-name rpc", halt_on_error: false, hide_output: true)
  result = my_exec("aws ecr get-login --no-include-email", hide_output: true)
  my_exec result[:stdout]
  my_exec 'docker build -t rpc .'
  acct = dc.aws_credentials[:account]
  my_exec "docker tag rpc:latest #{acct}.dkr.ecr.#{region}.amazonaws.com/rpc:latest"
  my_exec "docker push #{acct}.dkr.ecr.#{region}.amazonaws.com/rpc:latest"
end

task :build_updater_docker do
  dockerdir = Pathname.new(__dir__).join('docker/parity/updater')
  Dir.chdir(dockerdir)
  region = ENV['AWS_DEFAULT_REGION']
  my_exec("aws ecr create-repository --repository-name updater", halt_on_error: false, hide_output: true)
  result = my_exec("aws ecr get-login --no-include-email", hide_output: true)
  my_exec result[:stdout]
  my_exec 'docker build -t updater .'
  acct = dc.aws_credentials[:account]
  my_exec "docker tag updater:latest #{acct}.dkr.ecr.#{region}.amazonaws.com/updater:latest"
  my_exec "docker push #{acct}.dkr.ecr.#{region}.amazonaws.com/updater:latest"
end

desc "Build docker images"
task :docker => [:confirm_can_build, :build_rpc_docker, :build_updater_docker] do
end

task :default => [:docker]
