# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/object/blank'
require 'json'
require 'pathname'
require 'colorize'
require 'open3'
require 'erb'

def random_text(number)
  charset = Array('a'..'z')
  Array.new(number) { charset.sample }.join
end

def my_exec(cmd, halt_on_error: true, hide_output: false, hide_command: false)
  print "Executing: "
  if hide_command
    puts "<redacted>".white.bold
  else
    puts "#{cmd}".white.bold
  end
  stdout, stderr, status = Open3.capture3(cmd)
  print stdout unless hide_output
  if status.exitstatus != 0
    print stderr unless hide_output
    puts "Previous command reported error code #{status}" unless hide_output
    exit(status.exitstatus) if halt_on_error
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
      aws_env[:account] = credentials['Account']
      aws_env[:username] = username
      print "Using AWS CLI as account #{aws_env[:account]}, user #{aws_env[:username]}. "
      puts 'Set AWS_PROFILE to change this.'
      sleep(3) # give user a chance to break
    else
      exit(1)
    end
  end

  def check_for_aws_cli
    cli_installed = my_exec('which aws')
    if cli_installed.blank?
      puts 'AWS CLI not installed. Please install to continue. Instructions here:'
      puts 'https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html'
      exit(1)
    else
      region = ENV['AWS_DEFAULT_REGION']
      if region.blank?
        puts 'Please set AWS_DEFAULT_REGION'
        exit(1)
      else
        aws_env[:region] = region
        parse_credentials
      end
    end
  end

  def check_for_docker
    docker_installed = `which docker`
    if docker_installed.blank?
      puts 'Docker not installed. Please install docker.'
      exit(1)
    end
  end
end

dc = DependencyChecker.new

desc 'Check for dependencies'
task :confirm_can_build do
  dc.check_for_aws_cli
  dc.check_for_docker
end

class DockerBuilder
  def initialize(dependency_checker, name)
    @dependency_checker = dependency_checker
    @name = name
  end

  def set_docker_parameters
    region = @dependency_checker.aws_env[:region]
    acct = @dependency_checker.aws_env[:account]
    @image_name = "#{acct}.dkr.ecr.#{region}.amazonaws.com/#{@name}:latest"
    @dependency_checker.aws_env["#{@name}_image_name".to_sym] = @image_name
  end

  def build
    set_docker_parameters
    dockerdir = Pathname.new(__dir__).join("docker/parity/#{@name}")
    startingdir = Dir.pwd
    Dir.chdir(dockerdir)
    my_exec("aws ecr create-repository --repository-name #{@name}", halt_on_error: false, hide_output: true)
    result = my_exec('aws ecr get-login --no-include-email', hide_output: true)
    my_exec(result[:stdout], hide_command: true)
    my_exec "docker build -t #{@name} ."
    my_exec "docker tag #{@name}:latest #{@image_name}"
    my_exec "docker push #{@image_name}"
    Dir.chdir(startingdir)
  end
end

task :build_rpc_docker do
  builder = DockerBuilder.new(dc, 'rpc')
  builder.build
end

task :build_updater_docker do
  builder = DockerBuilder.new(dc, 'updater')
  builder.build
end

task :set_docker_parameters => :confirm_can_build do
  builder = DockerBuilder.new(dc, 'rpc')
  builder.set_docker_parameters
  builder = DockerBuilder.new(dc, 'updater')
  builder.set_docker_parameters
end

desc 'Build docker images'
task docker: %i[confirm_can_build build_rpc_docker build_updater_docker] do
end

desc 'Generate unique bucket prefix'
task generate_unique_prefix: :set_docker_parameters do
  suffix = random_text(20)
  cmd = "aws ssm put-parameter --name '/EcsRpcService/suffix' --type 'String' --value '#{suffix}' --no-overwrite"
  my_exec(cmd, halt_on_error: false, hide_output: true)
end

desc 'Create S3 bucket for CloudFormation templates'
task create_template_bucket: :generate_unique_prefix do
  result = my_exec("aws ssm get-parameter --name '/EcsRpcService/suffix'", hide_output: true)
  h = JSON.parse(result[:stdout])
  dc.aws_env[:suffix] = h['Parameter']['Value']
  cmd = "aws s3 mb s3://ecs-rpc-service-templates-#{dc.aws_env[:suffix]}"
  my_exec(cmd, halt_on_error: false, hide_output: true)
end

desc 'Push CloudFormation updates'
task push_cfn_templates: :create_template_bucket do
  begin
    Dir.mkdir('build')
  rescue StandardError
    nil
  end
  suffix = dc.aws_env[:suffix]
  renderer = ERB.new(File.read('templates/master.yml.erb'))
  File.open('build/master.yml', 'w') do |file|
    file << renderer.result(binding)
  end
  my_exec('cp templates/*.yml build')
  cmd = "aws s3 cp build s3://ecs-rpc-service-templates-#{dc.aws_env[:suffix]} --recursive"
  my_exec(cmd, halt_on_error: false)
end

desc 'Interpolate parameters from previous tasks'
task interpolate_params: :push_cfn_templates do
  params = JSON.parse(File.read('config/params.json'))
  params.push(
    'ParameterKey' => 'RpcDockerImage',
    'ParameterValue' => dc.aws_env[:rpc_image_name]
  )
  params.push(
    'ParameterKey' => 'UpdaterDockerImage',
    'ParameterValue' => dc.aws_env[:updater_image_name]
  )
  File.open('build/params.json', 'w') do |file|
    file << params.to_json
  end
end

desc 'Create master CloudFormation stack'
task create_cfn_stack: :interpolate_params do
  params = JSON.parse(File.read('build/params.json'))
  param = params.find {|param| param['ParameterKey'] == 'EnvironmentName' }
  stack_name = param['ParameterValue']
  cmd = "aws cloudformation create-stack --stack-name #{stack_name} " +
        "--template-url https://s3.amazonaws.com/ecs-rpc-service-templates-#{dc.aws_env[:suffix]}/master.yml " +
        '--parameters file://build/params.json ' +
        '--capabilities CAPABILITY_NAMED_IAM'
  my_exec(cmd)
end

task default: [:docker, :create_cfn_stack]
