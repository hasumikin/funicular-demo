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

  desc "Create CloudFormation stack (requires all parameters)"
  task :create do
    require_aws_cli!

    region = detect_region

    puts "CloudFormation stack creation requires the following parameters:"
    puts "  - KeyPairName: EC2 Key Pair for SSH access"
    puts "  - HostedZoneId: Route53 Hosted Zone ID"
    puts "  - VpcId: VPC ID"
    puts "  - SubnetId: Public subnet ID"
    puts ""

    params = {}
    %w[KeyPairName HostedZoneId VpcId SubnetId].each do |param|
      print "Enter #{param}: "
      params[param] = STDIN.gets.strip
      abort "#{param} is required" if params[param].empty?
    end

    instance_type = "t2.micro"
    print "Enter InstanceType [#{instance_type}]: "
    user_type = STDIN.gets.strip
    instance_type = user_type unless user_type.empty?

    param_args = params.map { |k, v| "ParameterKey=#{k},ParameterValue=#{v}" }
    param_args << "ParameterKey=InstanceType,ParameterValue=#{instance_type}"

    puts "\nCreating stack '#{STACK_NAME}' in #{region}..."
    success = system(
      "aws", "cloudformation", "create-stack",
      "--stack-name", STACK_NAME,
      "--template-body", "file://#{TEMPLATE_PATH}",
      "--parameters", *param_args,
      "--capabilities", "CAPABILITY_IAM",
      "--region", region
    )

    abort "Failed to initiate stack creation" unless success

    puts "Waiting for stack creation to complete..."
    success = system(
      "aws", "cloudformation", "wait", "stack-create-complete",
      "--stack-name", STACK_NAME,
      "--region", region
    )

    if success
      puts "Stack creation completed successfully!"
      Rake::Task["infra:status"].invoke
    else
      abort "Stack creation failed. Check AWS Console for details."
    end
  end

  desc "Delete CloudFormation stack and all resources"
  task :delete do
    require_aws_cli!

    region = detect_region

    puts "WARNING: This will delete the entire '#{STACK_NAME}' stack and all resources."
    puts "Are you sure? (type 'DELETE' to confirm): "
    confirmation = STDIN.gets.strip

    abort "Deletion cancelled." unless confirmation == "DELETE"

    puts "Starting ECR cleanup..."
    ecr_repo = "rails-chat"

    # Get image IDs and delete them
    images_json = `aws ecr describe-images \
      --repository-name #{ecr_repo} \
      --region #{region} \
      --query 'imageDetails[*].imageId' \
      --output json 2>/dev/null`.strip

    unless images_json.empty? || images_json == "[]"
      images = JSON.parse(images_json)
      if images.any?
        puts "Found #{images.length} image(s) in ECR. Deleting..."
        images.each do |image_id|
          system(
            "aws", "ecr", "batch-delete-image",
            "--repository-name", ecr_repo,
            "--image-ids", image_id.to_json,
            "--region", region,
            out: File::NULL,
            err: File::NULL
          )
        end
        puts "ECR images deleted."
      end
    end

    puts "Deleting CloudFormation stack..."
    success = system(
      "aws", "cloudformation", "delete-stack",
      "--stack-name", STACK_NAME,
      "--region", region
    )

    abort "Failed to initiate stack deletion" unless success

    puts "Waiting for stack deletion to complete..."
    success = system(
      "aws", "cloudformation", "wait", "stack-delete-complete",
      "--stack-name", STACK_NAME,
      "--region", region
    )

    if success
      puts "✓ Stack deletion completed successfully!"
    else
      puts "⚠ Stack deletion completed with errors. Check AWS Console for details."
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
