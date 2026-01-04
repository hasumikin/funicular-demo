namespace :infra do
  STACK_NAME = "rails-chat-infrastructure"
  TEMPLATE_PATH = "infrastructure/cloudformation.yml"

  desc "Update CloudFormation stack with current template"
  task :update do
    require_aws_cli!

    region = detect_region
    puts "Updating stack '#{STACK_NAME}' in #{region}..."

    success = system(
      "aws", "cloudformation", "update-stack",
      "--stack-name", STACK_NAME,
      "--template-body", "file://#{TEMPLATE_PATH}",
      "--parameters",
      "ParameterKey=KeyPairName,UsePreviousValue=true",
      "ParameterKey=HostedZoneId,UsePreviousValue=true",
      "ParameterKey=VpcId,UsePreviousValue=true",
      "ParameterKey=SubnetId,UsePreviousValue=true",
      "--capabilities", "CAPABILITY_IAM",
      "--region", region
    )

    abort "Failed to initiate stack update" unless success

    puts "Waiting for stack update to complete..."
    success = system(
      "aws", "cloudformation", "wait", "stack-update-complete",
      "--stack-name", STACK_NAME,
      "--region", region
    )

    if success
      puts "Stack update completed successfully!"
      Rake::Task["infra:status"].invoke
    else
      abort "Stack update failed. Check AWS Console for details."
    end
  end

  desc "Show current stack status and outputs"
  task :status do
    require_aws_cli!

    region = detect_region
    puts "Stack: #{STACK_NAME} (#{region})"
    puts "-" * 50

    # Get stack status
    status = `aws cloudformation describe-stacks \
      --stack-name #{STACK_NAME} \
      --query "Stacks[0].StackStatus" \
      --output text \
      --region #{region} 2>/dev/null`.strip

    if status.empty?
      abort "Stack '#{STACK_NAME}' not found"
    end

    puts "Status: #{status}"

    # Get outputs
    outputs = `aws cloudformation describe-stacks \
      --stack-name #{STACK_NAME} \
      --query "Stacks[0].Outputs[*].[OutputKey,OutputValue]" \
      --output text \
      --region #{region} 2>/dev/null`

    unless outputs.strip.empty?
      puts "\nOutputs:"
      outputs.each_line do |line|
        key, value = line.strip.split(/\s+/, 2)
        puts "  #{key}: #{value}"
      end
    end

    # Get current instance type parameter
    instance_type = `aws cloudformation describe-stacks \
      --stack-name #{STACK_NAME} \
      --query "Stacks[0].Parameters[?ParameterKey=='InstanceType'].ParameterValue" \
      --output text \
      --region #{region} 2>/dev/null`.strip

    puts "\nInstance Type: #{instance_type}" unless instance_type.empty?
  end

  desc "Validate CloudFormation template"
  task :validate do
    require_aws_cli!

    puts "Validating #{TEMPLATE_PATH}..."
    success = system(
      "aws", "cloudformation", "validate-template",
      "--template-body", "file://#{TEMPLATE_PATH}"
    )

    if success
      puts "Template is valid."
    else
      abort "Template validation failed."
    end
  end

  private

  def require_aws_cli!
    unless system("which aws > /dev/null 2>&1")
      abort "AWS CLI is required but not installed."
    end
  end

  def detect_region
    # Try to get region from deploy.yml ECR server
    if File.exist?("config/deploy.yml")
      content = File.read("config/deploy.yml")
      if content =~ /\.dkr\.ecr\.([a-z0-9-]+)\.amazonaws\.com/
        return $1
      end
    end

    # Fall back to AWS CLI default or environment variable
    ENV["AWS_REGION"] || ENV["AWS_DEFAULT_REGION"] || "ap-northeast-1"
  end
end
