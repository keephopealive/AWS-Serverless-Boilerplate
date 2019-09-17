


#! * Pre-Setup *
#TODO   Assuming VSCode is used for viewing this file, for ease of readability, download the following plugins in VSCode: Better Comments
#TODO   Plugins for development: CloudFormation, YAML, vscode-cfn-lint
#TODO   In VSC Settings for YAML extension, include:

"yaml.customTags": [
  "!And",
  "!If",
  "!Not Scalar",
  "!Not Sequence",
  "!Not",
  "!Equals",
  "!Or",
  "!FindInMap",
  "!Base64",
  "!Cidr",
  "!Ref",
  "!Sub",
  "!GetAtt",
  "!GetAZs",
  "!ImportValue",
  "!Select",
  "!Split",
  "!Join"
],
"yaml.validate": false,



#! * AWS Account Setup *
#TODO   Setup an AWS root account.
#TODO   Configure credentials and MFA (rules should apply to all new users).
#TODO   AWS > IAM has at least 1 Group named 'admin' with admin privilages
#TODO   Create an extra group for 'devs' with privilages specific to developers.
#TODO   Create at least 1 user (your personal/admin user account) assigned to the 'admin' group (achieving admin privilages). AWS Root account should not be used.
#TODO   Create at least 2 Roles ('dev' and 'prod'), which the user can assume. 
#?      Donwload Chrome Browser Plugin: 'AWS Extend Switch Roles' helps switch between roles while logged in AWS. 
#?      Add the following configuration:

[<!master-account-name!>]
aws_account_id = <master-account-id>

[Paragon Dev]
source_profile = <!master-account-name!>
role_name = OrganizationAccountAccessRole
aws_account_id = 99999999999999
region = us-west-2
color = 00a6ff

[Paragon Prod]
source_profile = <!master-account-name!>
role_name = OrganizationAccountAccessRole
aws_account_id = 88888888888888
region = us-west-2
color = ff0000


#******************************************
#* Repeat the follow steps (below this line) for each new AWS SAM Application (using multiple apps as a way to uphold a seperation of concerns between resources e.g. microservice for each SAM application)
#******************************************


#! Create a new AWS SAM Application (using nodejs10.x) (Requires the AWS and SAM CLI installation)
sam init --name <!aws-sam-github-repo-name!> -r nodejs10.x



#! Create a Github Repo for the AWS SAM Application <!aws-sam-github-repo-name!> with 4 branches ['master', 'development', 'testing', 'staging'] (locally and pushed to remote)
git init 
git add .
git commit -m 'initial commit' && git push -u origin master
git checkout -b development && git push -u origin development
git checkout -b testing && git push -u origin testing
git checkout -b staging && git push -u origin staging



#! Create a new folder for the AWS SAM Application's infrastructure pipeline.yaml file
mkdir <!sam-applications-infrastructure-repo-name!>
#! Create a new file in the folder 'pipeline.yaml' which will be used for:
#? Confiugration of the AWS SAM application for the following steps and stages:
#? Source
#? Build
#? Pipeline
#?    Source (upload repo / app into AWS)
#?    Build (package build the app)
#?    Beta (run unit testing on the app)
#?    Gamma (run integration testing on the app)
#?    Prod (release to production - master branch only)
#TODO Use the file: pipeline.yaml from the current directory (FIXME: note - pipeline.yaml includes more than the pipeline content, a different file name is necessary for better understanding of it's purpose)...

#TODO Alternative to the premade file above, utilize...
sam init --location gh:aws-samples/cookiecutter-aws-sam-pipeline
#TODO ...as a boilerplate starting point for the pipeline.



#! Store into AWS System Manager the sensitive or repeatable data needed on the <!github-infrastructure-name!>/pipeline.yaml file (for example, the repo name, (github user auth) token, and user name)
#? We will store the repo name, token and user into AWS System Manager so our pipeline file can reference these variables instead of the raw information on the file itself (for security purposes).



#? ##########################################################
#? Profile: paragon-dev
#? ##########################################################

#! Store REPO name into the AWS System Manager 
aws ssm put-parameter \
    --name "/service/<!aws-sam-github-repo-name!>/github/repo" \
    --description "Github Repository name for Cloudformation Stack <!aws-sam-github-repo-name!>-pipeline" \
    --type "String" \
    --value "<!aws-sam-github-repo-name!>" \
    --profile "paragon-dev"

#! Store TOKEN into the AWS System Manager
aws ssm put-parameter \
    --name "/service/<!aws-sam-github-repo-name!>/github/token" \
    --description "Github Token for Cloudformation Stack <!aws-sam-github-repo-name!>-pipeline" \
    --type "String" \
    --value "99999999999999999999999999999999999" \
    --profile "paragon-dev"

#! Store USER name into the AWS System Manager
aws ssm put-parameter \
    --name "/service/<!aws-sam-github-repo-name!>/github/user" \
    --description "Github Username for Cloudformation Stack <!aws-sam-github-repo-name!>-pipeline" \
    --type "String" \
    --value "paragontechdev" \
    --profile "paragon-dev"

#? ##########################################################
#? Branch: Development
#? Profile: paragon-dev
#? ##########################################################

#! <!aws-sam-github-repo-name!>-development
#! <!aws-sam-github-repo-name!>-development create-stack
aws cloudformation create-stack \
    --template-body file://pipeline.yaml \
    --stack-name <!aws-sam-github-repo-name!>-development \
    --parameters \
        ParameterKey=GithubBranch,ParameterValue=development \
        ParameterKey=GithubRepoAndBranch,ParameterValue=<!aws-sam-github-repo-name!>-development \
    --capabilities CAPABILITY_NAMED_IAM \
    --profile paragon-dev
#! <!aws-sam-github-repo-name!>-development update-stack
aws cloudformation update-stack \
    --template-body file://pipeline.yaml \
    --stack-name <!aws-sam-github-repo-name!>-development \
    --parameters \
        ParameterKey=GithubBranch,ParameterValue=development \
        ParameterKey=GithubRepoAndBranch,ParameterValue=<!aws-sam-github-repo-name!>-development \
    --capabilities CAPABILITY_NAMED_IAM \
    --profile paragon-dev
#! <!aws-sam-github-repo-name!>-dev show logs
aws cloudformation describe-stacks \
    --stack-name <!aws-sam-github-repo-name!>-development \
    --query 'Stacks[].Outputs' \
    --profile paragon-dev
#! <!aws-sam-github-repo-name!>-dev delete-stack
aws cloudformation delete-stack \
    --stack-name <!aws-sam-github-repo-name!>-development-Beta \
    --profile paragon-dev
aws cloudformation delete-stack \
    --stack-name <!aws-sam-github-repo-name!>-development-Gamma \
    --profile paragon-dev
aws cloudformation delete-stack \
    --stack-name <!aws-sam-github-repo-name!>-development-Prod \
    --profile paragon-dev
aws cloudformation delete-stack \
    --stack-name <!aws-sam-github-repo-name!>-development \
    --profile paragon-dev

#? ##########################################################
#? Branch: testing
#? Profile: paragon-dev
#? ##########################################################

#! <!aws-sam-github-repo-name!>-testing
#! <!aws-sam-github-repo-name!>-testing create-stack
aws cloudformation create-stack \
    --template-body file://pipeline.yaml \
    --stack-name <!aws-sam-github-repo-name!>-testing \
    --parameters ParameterKey=GithubBranch,ParameterValue=testing ParameterKey=GithubRepoAndBranch,ParameterValue=<!aws-sam-github-repo-name!>-testing \
    --capabilities CAPABILITY_NAMED_IAM \
    --profile paragon-dev
#! <!aws-sam-github-repo-name!>-testing update-stack
aws cloudformation update-stack \
    --template-body file://pipeline.yaml \
    --stack-name <!aws-sam-github-repo-name!>-testing \
    --parameters ParameterKey=GithubBranch,ParameterValue=testing ParameterKey=GithubRepoAndBranch,ParameterValue=<!aws-sam-github-repo-name!>-testing \
    --capabilities CAPABILITY_NAMED_IAM \
    --profile paragon-dev
#! <!aws-sam-github-repo-name!>-testing show logs
aws cloudformation describe-stacks \
    --stack-name <!aws-sam-github-repo-name!>-testing \
    --query 'Stacks[].Outputs' \
    --profile paragon-dev
#! <!aws-sam-github-repo-name!>-testing delete-stack
aws cloudformation delete-stack \
    --stack-name <!aws-sam-github-repo-name!>-testing-Beta \
    --profile paragon-dev
aws cloudformation delete-stack \
    --stack-name <!aws-sam-github-repo-name!>-testing-Gamma \
    --profile paragon-dev
aws cloudformation delete-stack \
    --stack-name <!aws-sam-github-repo-name!>-testing-Prod \
    --profile paragon-dev
aws cloudformation delete-stack \
    --stack-name <!aws-sam-github-repo-name!>-testing \
    --profile paragon-dev

#? ##########################################################
#? Branch: staging
#? Profile: paragon-dev
#? ##########################################################

#! <!aws-sam-github-repo-name!>-staging
#! <!aws-sam-github-repo-name!>-staging create-stack
aws cloudformation create-stack \
    --template-body file://pipeline.yaml \
    --stack-name <!aws-sam-github-repo-name!>-staging \
    --parameters ParameterKey=GithubBranch,ParameterValue=staging ParameterKey=GithubRepoAndBranch,ParameterValue=<!aws-sam-github-repo-name!>-staging \
    --capabilities CAPABILITY_NAMED_IAM \
    --profile paragon-dev
#! <!aws-sam-github-repo-name!>-staging update-stack
aws cloudformation update-stack \
    --template-body file://pipeline.yaml \
    --stack-name <!aws-sam-github-repo-name!>-staging \
    --parameters ParameterKey=GithubBranch,ParameterValue=staging ParameterKey=GithubRepoAndBranch,ParameterValue=<!aws-sam-github-repo-name!>-staging \
    --capabilities CAPABILITY_NAMED_IAM \
    --profile paragon-dev
#! <!aws-sam-github-repo-name!>-staging show logs
aws cloudformation describe-stacks \
    --stack-name <!aws-sam-github-repo-name!>-staging \
    --query 'Stacks[].Outputs' \
    --profile paragon-dev
#! <!aws-sam-github-repo-name!>-staging delete-stack
aws cloudformation delete-stack \
    --stack-name <!aws-sam-github-repo-name!>-staging-Beta \
    --profile paragon-dev
aws cloudformation delete-stack \
    --stack-name <!aws-sam-github-repo-name!>-staging-Gamma \
    --profile paragon-dev
aws cloudformation delete-stack \
    --stack-name <!aws-sam-github-repo-name!>-staging-Prod \
    --profile paragon-dev
aws cloudformation delete-stack \
    --stack-name <!aws-sam-github-repo-name!>-staging \
    --profile paragon-dev

#? ##########################################################
#? PRODUCTION --  - Profile: paragon-prod2
#? ##########################################################

#! Store REPO name into the AWS System Manager
aws ssm put-parameter \
    --name "/service/<!aws-sam-github-repo-name!>/github/repo" \
    --description "Github Repository name for Cloudformation Stack <!aws-sam-github-repo-name!>-pipeline" \
    --type "String" \
    --value "<!aws-sam-github-repo-name!>" \
    --profile "paragon-prod2"

#! Store TOKEN into the AWS System Manager
aws ssm put-parameter \
    --name "/service/<!aws-sam-github-repo-name!>/github/token" \
    --description "Github Token for Cloudformation Stack <!aws-sam-github-repo-name!>-pipeline" \
    --type "String" \
    --value "99999999999999999999999999999999999" \
    --profile "paragon-prod2"

#! Store USER name into the AWS System Manager
aws ssm put-parameter \
    --name "/service/<!aws-sam-github-repo-name!>/github/user" \
    --description "Github Username for Cloudformation Stack <!aws-sam-github-repo-name!>-pipeline" \
    --type "String" \
    --value "paragontechdev" \
    --profile "paragon-prod2"

#? ##########################################################
#? Branch: production
#? Profile: paragon-prod2
#? ##########################################################

#! <!aws-sam-github-repo-name!>-production (master)
#! <!aws-sam-github-repo-name!>-production create-stack (master)
aws cloudformation create-stack \
    --template-body file://pipeline.yaml \
    --stack-name <!aws-sam-github-repo-name!>-production \
    --parameters ParameterKey=GithubBranch,ParameterValue=master ParameterKey=GithubRepoAndBranch,ParameterValue=<!aws-sam-github-repo-name!>-production \
    --capabilities CAPABILITY_NAMED_IAM \
    --profile paragon-prod2
#! <!aws-sam-github-repo-name!>-production update-stack (master)
aws cloudformation update-stack \
    --template-body file://pipeline.yaml \
    --stack-name <!aws-sam-github-repo-name!>-production \
    --parameters ParameterKey=GithubBranch,ParameterValue=master ParameterKey=GithubRepoAndBranch,ParameterValue=<!aws-sam-github-repo-name!>-production \
    --capabilities CAPABILITY_NAMED_IAM \
    --profile paragon-prod2
#! <!aws-sam-github-repo-name!>-production show logs (master)
aws cloudformation describe-stacks \
    --stack-name <!aws-sam-github-repo-name!>-production \
    --query 'Stacks[].Outputs' \
    --profile paragon-prod2
#! <!aws-sam-github-repo-name!>-production delete-stack (master)
aws cloudformation delete-stack \
    --stack-name <!aws-sam-github-repo-name!>-production \
    --profile paragon-prod2



#? ##########################################################
#? ##########################################################
#? ##########################################################
#? pipeline.yaml
#? ##########################################################
#? ##########################################################
#? ##########################################################





AWSTemplateFormatVersion: 2010-09-09


#!  ██████╗ ██╗      ██████╗ ██████╗  █████╗ ██╗         ██████╗  █████╗ ██████╗  █████╗ ███╗   ███╗███████╗████████╗███████╗██████╗ ███████╗
#! ██╔════╝ ██║     ██╔═══██╗██╔══██╗██╔══██╗██║         ██╔══██╗██╔══██╗██╔══██╗██╔══██╗████╗ ████║██╔════╝╚══██╔══╝██╔════╝██╔══██╗██╔════╝
#! ██║  ███╗██║     ██║   ██║██████╔╝███████║██║         ██████╔╝███████║██████╔╝███████║██╔████╔██║█████╗     ██║   █████╗  ██████╔╝███████╗
#! ██║   ██║██║     ██║   ██║██╔══██╗██╔══██║██║         ██╔═══╝ ██╔══██║██╔══██╗██╔══██║██║╚██╔╝██║██╔══╝     ██║   ██╔══╝  ██╔══██╗╚════██║
#! ╚██████╔╝███████╗╚██████╔╝██████╔╝██║  ██║███████╗    ██║     ██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║███████╗   ██║   ███████╗██║  ██║███████║
#!  ╚═════╝ ╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝    ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚══════╝

#! Defined here, to be referenced throughout the file.                                                                                                                                          
Parameters:
  GithubRepo:
    Type: AWS::SSM::Parameter::Value<String>
    Default: /service/<!aws-sam-github-repo-name!>/github/repo
  GithubToken:
    Type: AWS::SSM::Parameter::Value<String>
    NoEcho: true
    Default: /service/<!aws-sam-github-repo-name!>/github/token
  GithubUser:
    Type: AWS::SSM::Parameter::Value<String>
    Default: /service/<!aws-sam-github-repo-name!>/github/user
  GithubRepoAndBranch:
    Type: String
    Description: Repo name + Branch name (repo-name-branch)
  GithubBranch: 
    Type: String
    AllowedValues: 
      - development
      - testing
      - staging
      - master
    Description: Branch name

Conditions: 
  IsMasterBranch: !Equals [ !Ref GithubBranch, master ]

Resources:
 

#!  ███████╗ ██████╗ ██╗   ██╗██████╗  ██████╗███████╗     ██████╗ ██████╗ ██████╗ ███████╗
#!  ██╔════╝██╔═══██╗██║   ██║██╔══██╗██╔════╝██╔════╝    ██╔════╝██╔═══██╗██╔══██╗██╔════╝
#!  ███████╗██║   ██║██║   ██║██████╔╝██║     █████╗      ██║     ██║   ██║██║  ██║█████╗  
#!  ╚════██║██║   ██║██║   ██║██╔══██╗██║     ██╔══╝      ██║     ██║   ██║██║  ██║██╔══╝  
#!  ███████║╚██████╔╝╚██████╔╝██║  ██║╚██████╗███████╗    ╚██████╗╚██████╔╝██████╔╝███████╗
#!  ╚══════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚══════╝     ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝

    #! CREATE: an S3 Bucket (Type: AWS::S3::Bucket), with encryption (BucketEncryption: ...)
    #! USED TO: Store the SOURCE CODE, which includes Project Files (SAM Framework Files).
    BuildArtifactsBucket: # Resource Name: BuildArtifactsBucket
      Type: AWS::S3::Bucket # Resource Type: AWS::S3::Bucket
      Properties:
        BucketEncryption: # Encryption Configuration for Resources in Bucket
          ServerSideEncryptionConfiguration:
            - ServerSideEncryptionByDefault:
                SSEAlgorithm: AES256
        Tags: 
          - 
            Key: "Stack"
            Value: !Ref AWS::StackName
          -
            Key: "Project"
            Value: !Sub ${GithubRepoAndBranch}
      DeletionPolicy: Retain
          
      
#!  ██████╗ ██████╗ ██████╗ ███████╗    ██████╗ ██╗   ██╗██╗██╗     ██████╗ 
#! ██╔════╝██╔═══██╗██╔══██╗██╔════╝    ██╔══██╗██║   ██║██║██║     ██╔══██╗
#! ██║     ██║   ██║██║  ██║█████╗      ██████╔╝██║   ██║██║██║     ██║  ██║
#! ██║     ██║   ██║██║  ██║██╔══╝      ██╔══██╗██║   ██║██║██║     ██║  ██║
#! ╚██████╗╚██████╔╝██████╔╝███████╗    ██████╔╝╚██████╔╝██║███████╗██████╔╝
#!  ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝    ╚═════╝  ╚═════╝ ╚═╝╚══════╝╚═════╝
                                                                         
    #! CREATE: a CodeBuild Project (Type: AWS::CodeBuild::Project), (Name: ___), (Environment: ____), (Source:BuildSpec: Phases: ( install, pre_build, build, post_build )), (Cache: ____)
    #! USED TO: Define the Build Process of the SOURCE CODE && Output Bucket of the built source code (Cache / Location / BuildArtifactsBucket)
    # Cached files go in BuildArtifactsBucket
    CodeBuildProject:
        Type: AWS::CodeBuild::Project # Resource Type: AWS::CodeBuild::Project
        Properties:
            # Name: <!aws-sam-github-repo-name!> # The name of the build project. The name must be unique across all of the projects in your AWS account.
            Name: !Ref GithubRepoAndBranch # The name of the build project. The name must be unique across all of the projects in your AWS account.
            Artifacts: # Artifacts is a property of the AWS::CodeBuild::Project resource that specifies output settings for artifacts generated by an AWS CodeBuild build.
              Type: CODEPIPELINE
            Environment: 
                Type: LINUX_CONTAINER
                ComputeType: BUILD_GENERAL1_SMALL
                Image: aws/codebuild/amazonlinux2-x86_64-standard:1.0
                EnvironmentVariables:
                  - 
                    Name: BUILD_OUTPUT_BUCKET
                    Value: !Ref BuildArtifactsBucket
            Cache:
              Type: S3
              Location: !Sub ${BuildArtifactsBucket}/codebuild-cache
            ServiceRole: !GetAtt CodeBuildServiceRole.Arn
            Source: 
                Type: CODEPIPELINE
                BuildSpec: |
                  version: 0.2
                  phases:
                    install:
                      runtime-versions:
                        nodejs: 10
                      commands:
                        # Use Install phase to install packages or any pre-reqs you may need throughout the build (e.g. dev deps, security checks, etc.)
                        - echo " >>>>>>>>>>>>>>>>>>>>>>>>>> [Install phase] <<<<<<<<<<<<<<<<<<<<<<<<<<<<"
                        - pip3 install --user aws-sam-cli
                        - USER_BASE_PATH=$(python -m site --user-base)
                        - export PATH=$PATH:$USER_BASE_PATH/bin
                    pre_build:
                      commands:
                        # Use Pre-Build phase to run tests, install any code deps or any other customization before build
                        - echo " >>>>>>>>>>>>>>>>>>>>>>>>>> [Pre-Build phase] <<<<<<<<<<<<<<<<<<<<<<<<<<<<"
                        - pwd
                        - echo "$ cd functions/hello-world"
                        - cd functions/hello-world
                        - pwd
                        - ls
                        - echo "$ npm install"
                        - npm install
                        - echo "$ cd ../../"
                        - cd ../../
                        - pwd
                    build:
                      commands:
                        # Use Build phase to build your artifacts (compile, package, etc.)
                        - echo " >>>>>>>>>>>>>>>>>>>>>>>>>> [Build phase] <<<<<<<<<<<<<<<<<<<<<<<<<<<<"
                        # We package the SAM template and create `packaged.yaml` file that will be used in our pipeline for deployment
                        ## Here we separate Build from Deployment and segregate permissions for different steps
                        - echo "Starting SAM packaging `date` in `pwd`"
                        # - aws cloudformation package ....  # This was the default
                        - sam package --template-file template.yaml --s3-bucket $BUILD_OUTPUT_BUCKET --output-template-file packaged.yaml
                    post_build:
                      commands:
                        # Use Post Build for notifications, git tags and any further customization after build
                        - echo " >>>>>>>>>>>>>>>>>>>>>>>>>> [Post-Build phase] <<<<<<<<<<<<<<<<<<<<<<<<<<<<"
                        - echo "SAM packaging completed on `date`"
                  ##################################
                  # Build Artifacts to be uploaded #
                  ##################################
                  artifacts:
                    files:
                      # list of local files relative to this build environment that will be added to the final artifact (zip)
                      - packaged.yaml
                    discard-paths: yes
                  #########################################
                  # Cache local files for subsequent runs #
                  #########################################
                  cache:
                    paths:
                    # List of path that CodeBuild will upload to S3 Bucket and use in subsequent runs to speed up Builds
                    - '/root/.cache/pip'
            Tags: 
              - 
                Key: "Stack"
                Value: !Ref AWS::StackName
              -
                Key: "Project"
                Value: !Ref GithubRepoAndBranch


#!  ██████╗ ██████╗ ██████╗ ███████╗    ██████╗ ██╗   ██╗██╗██╗     ██████╗     ██╗ █████╗ ███╗   ███╗
#! ██╔════╝██╔═══██╗██╔══██╗██╔════╝    ██╔══██╗██║   ██║██║██║     ██╔══██╗    ██║██╔══██╗████╗ ████║
#! ██║     ██║   ██║██║  ██║█████╗      ██████╔╝██║   ██║██║██║     ██║  ██║    ██║███████║██╔████╔██║
#! ██║     ██║   ██║██║  ██║██╔══╝      ██╔══██╗██║   ██║██║██║     ██║  ██║    ██║██╔══██║██║╚██╔╝██║
#! ╚██████╗╚██████╔╝██████╔╝███████╗    ██████╔╝╚██████╔╝██║███████╗██████╔╝    ██║██║  ██║██║ ╚═╝ ██║
#!  ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝    ╚═════╝  ╚═════╝ ╚═╝╚══════╝╚═════╝     ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝
                                                                                                   
    #! CREATE: a CodeBuildService Role (Type: AWS::IAM::Role)
    #! USED TO: specify allowed __actions__ for specific ___policies__ using specific __resources__
    #! Policies e.g.: CodeBuildLogs -- CodeBuildArtifactsBucket -- CodeBuildParameterStore
    #! Resources e.g.: - !Sub 'arn:aws:s3:::${BuildArtifactsBucket}/*'
    CodeBuildServiceRole:
        Type: AWS::IAM::Role
        Properties:
            AssumeRolePolicyDocument:
                Version: '2012-10-17'
                Statement:
                  - Action: 
                      - 'sts:AssumeRole'
                    Effect: Allow
                    Principal:
                      Service:
                        - codebuild.amazonaws.com
            Path: /
            Policies:
                - PolicyName: CodeBuildLogs
                  PolicyDocument:
                    Version: '2012-10-17'
                    Statement:
                      - 
                        Effect: Allow
                        Action:
                          - 'logs:CreateLogGroup'
                          - 'logs:CreateLogStream'
                          - 'logs:PutLogEvents'
                        Resource:
                          # - !Sub 'arn:aws:logs:${AWS::Region}:${AWS::AccountId}:log-group:/aws/codebuild/<!aws-sam-github-repo-name!>'
                          # - !Sub 'arn:aws:logs:${AWS::Region}:${AWS::AccountId}:log-group:/aws/codebuild/<!aws-sam-github-repo-name!>:*'
                          - !Sub 'arn:aws:logs:${AWS::Region}:${AWS::AccountId}:log-group:/aws/codebuild/${GithubRepoAndBranch}'
                          - !Sub 'arn:aws:logs:${AWS::Region}:${AWS::AccountId}:log-group:/aws/codebuild/${GithubRepoAndBranch}:*'
                - PolicyName: CodeBuildArtifactsBucket
                  PolicyDocument:
                    Version: '2012-10-17'
                    Statement:
                      - 
                        Effect: Allow
                        Action: 
                          - 's3:GetObject'
                          - 's3:GetObjectVersion'
                          - 's3:PutObject'
                        Resource:
                          - !Sub 'arn:aws:s3:::${BuildArtifactsBucket}/*'
                - PolicyName: CodeBuildParameterStore
                  PolicyDocument:
                    Version: '2012-10-17'
                    Statement:
                      -
                        Effect: Allow
                        Action: 'ssm:GetParameters'
                        Resource: '*'


#!   ██████╗██╗      ██████╗ ██╗   ██╗██████╗     ███████╗ ██████╗ ██████╗ ███╗   ███╗ █████╗ ████████╗██╗ ██████╗ ███╗   ██╗    ██╗ █████╗ ███╗   ███╗
#!  ██╔════╝██║     ██╔═══██╗██║   ██║██╔══██╗    ██╔════╝██╔═══██╗██╔══██╗████╗ ████║██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║    ██║██╔══██╗████╗ ████║
#!  ██║     ██║     ██║   ██║██║   ██║██║  ██║    █████╗  ██║   ██║██████╔╝██╔████╔██║███████║   ██║   ██║██║   ██║██╔██╗ ██║    ██║███████║██╔████╔██║
#!  ██║     ██║     ██║   ██║██║   ██║██║  ██║    ██╔══╝  ██║   ██║██╔══██╗██║╚██╔╝██║██╔══██║   ██║   ██║██║   ██║██║╚██╗██║    ██║██╔══██║██║╚██╔╝██║
#!  ╚██████╗███████╗╚██████╔╝╚██████╔╝██████╔╝    ██║     ╚██████╔╝██║  ██║██║ ╚═╝ ██║██║  ██║   ██║   ██║╚██████╔╝██║ ╚████║    ██║██║  ██║██║ ╚═╝ ██║
#!   ╚═════╝╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝     ╚═╝      ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝    ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝

    #! CREATE: a CloudFormationExecution Role (Type: AWS::IAM::Role)
    #! USED TO: specify allowed __actions__ for a specific AssumeRolePolicyDocument for a specific service: cloudformation.amazonaws.com
    CloudFormationExecutionRole:
      Type: AWS::IAM::Role
      Properties:
        AssumeRolePolicyDocument:
          Version: '2012-10-17'
          Statement:
            Action: 'sts:AssumeRole'
            Effect: Allow
            Principal:
              Service: cloudformation.amazonaws.com
        Path: /
        ManagedPolicyArns:
          - 'arn:aws:iam::aws:policy/AdministratorAccess'


#! ██████╗ ██╗██████╗ ███████╗██╗     ██╗███╗   ██╗███████╗
#! ██╔══██╗██║██╔══██╗██╔════╝██║     ██║████╗  ██║██╔════╝
#! ██████╔╝██║██████╔╝█████╗  ██║     ██║██╔██╗ ██║█████╗  
#! ██╔═══╝ ██║██╔═══╝ ██╔══╝  ██║     ██║██║╚██╗██║██╔══╝  
#! ██║     ██║██║     ███████╗███████╗██║██║ ╚████║███████╗
#! ╚═╝     ╚═╝╚═╝     ╚══════╝╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝
    
    #! CREATE: a Pipeline (Type: AWS::CodePipeline::Pipeline)
    #! USED TO: 
    Pipeline: 
      Type: AWS::CodePipeline::Pipeline # creates a CodePipeline pipeline that describes how software changes go through a release process.
      Properties:
        ArtifactStore: 
          Location: !Ref BuildArtifactsBucket # specify where the source code exists
          Type: S3
        Name: !Ref GithubRepoAndBranch
        RoleArn: !GetAtt CodePipelineExecutionRole.Arn
        Stages:
            
          #!    _____ ____  __  ______  ____________
          #!   / ___// __ \/ / / / __ \/ ____/ ____/
          #!   \__ \/ / / / / / / /_/ / /   / __/   
          #!  ___/ / /_/ / /_/ / _, _/ /___/ /___   
          #! /____/\____/\____/_/ |_|\____/_____/                                     
          #! STAGE 1 = SOURCE - Retrieve the SOURCE CODE using the below configuration of: GITHUB: USER, REPO, BRANCH, AUTHTOKEN
          - Name: Source
            Actions:
              - Name: SourceCodeRepo
                ActionTypeId:
                  Category: Source
                  Owner: ThirdParty
                  Provider: GitHub
                  Version: "1"
                Configuration:
                  Owner: !Ref GithubUser        #? USER (referenced from the paramters at the top of the file )
                  Repo: !Ref GithubRepo         #? REPO (referenced from the paramters at the top of the file )
                  Branch: !Ref GithubBranch                #! Production (master branch)
                  OAuthToken: !Ref GithubToken  #? AUTHTOKEN (referenced from the paramters at the top of the file )
                OutputArtifacts: 
                  - Name: SourceCodeAsZip       #! COPY the SOURCE CODE into the __ SourceCodeAsZip __ file.
                RunOrder: 1

          #!     ____  __  ________    ____ 
          #!    / __ )/ / / /  _/ /   / __ \
          #!   / __  / / / // // /   / / / /
          #!  / /_/ / /_/ // // /___/ /_/ / 
          #! /_____/\____/___/_____/_____/  
          #! STAGE 2 = BUILD - Build the SOURCE CODE using the __ CodeBuildProject __ configurations.
          #! ...and move it into BuildArtifactAsZip 
          - Name: Build
            Actions:
              - Name: CodeBuild
                ActionTypeId:
                  Category: Build
                  Owner: AWS
                  Provider: CodeBuild
                  Version: "1"
                Configuration:
                  ProjectName: !Ref CodeBuildProject #! <--- Specifying the CodeBuildProject used to BUILD the SOURCE CODE
                InputArtifacts:
                  - Name: SourceCodeAsZip #! <--- Specifying the Input for the *SOURCE CODE*, from (from Stage 1) __ SourceCodeAsZip __
                OutputArtifacts:
                  - Name: BuildArtifactAsZip #! <--- Specifying the Output, for the *BUILT CODE* to __ BuildArtifactsAsZip __
          
          #!     ____  _______________ 
          #!    / __ )/ ____/_  __/   |
          #!   / __  / __/   / / / /| |
          #!  / /_/ / /___  / / / ___ |
          #! /_____/_____/ /_/ /_/  |_|
          #! STAGE 3 = BETA 
          #! This is the first step for your app's deployment. 
          #! Using the SAM template packaged in the Build step, you deploy the Lambda function and API Gateway endpoint to the beta stage. 
          #! At the end of the deployment, this stage run your test function against the beta API.
          - Name: Beta
            Actions:
              - Name: CreateChangeSet
                ActionTypeId:
                  Category: Deploy
                  Owner: AWS
                  Provider: CloudFormation
                  Version: "1"
                Configuration:
                          #! More info on Possible Values for Cloudformation: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/continuous-delivery-codepipeline-action-reference.html#w2ab2c13c13b9
                  ActionMode: CHANGE_SET_REPLACE
                  RoleArn: !GetAtt CloudFormationExecutionRole.Arn
                  StackName: !Sub ${GithubRepoAndBranch}-Beta
                  ChangeSetName: !Sub ${GithubRepoAndBranch}-ChangeSet-Beta
                  TemplatePath: BuildArtifactAsZip::packaged.yaml
                  Capabilities: CAPABILITY_IAM
                InputArtifacts:
                  - Name: BuildArtifactAsZip
                RunOrder: 1
              - Name: ExecuteChangeSet
                ActionTypeId:
                  Category: Deploy
                  Owner: AWS
                  Provider: CloudFormation
                  Version: "1"
                Configuration:
                  ActionMode: CHANGE_SET_EXECUTE
                  RoleArn: !GetAtt CloudFormationExecutionRole.Arn
                  StackName: !Sub ${GithubRepoAndBranch}-Beta
                  ChangeSetName: !Sub ${GithubRepoAndBranch}-ChangeSet-Beta
                OutputArtifacts:
                  - Name: !Sub ${GithubRepoAndBranch}BetaChangeSet
                RunOrder: 2
          
          #!    _________    __  _____  ______ 
          #!   / ____/   |  /  |/  /  |/  /   |
          #!  / / __/ /| | / /|_/ / /|_/ / /| |
          #! / /_/ / ___ |/ /  / / /  / / ___ |
          #! \____/_/  |_/_/  /_/_/  /_/_/  |_|
          #! STAGE 4 = GAMMA 
          #! Push the updated function and API to the gamma stage, then run the integration tests again.
          - Name: Gamma
            Actions:
              - Name: CreateChangeSet
                ActionTypeId:
                  Category: Deploy
                  Owner: AWS
                  Provider: CloudFormation
                  Version: "1"
                Configuration:
                  ActionMode: CHANGE_SET_REPLACE
                  RoleArn: !GetAtt CloudFormationExecutionRole.Arn
                  StackName: !Sub ${GithubRepoAndBranch}-Gamma
                  ChangeSetName: !Sub ${GithubRepoAndBranch}-ChangeSet-Gamma
                  TemplatePath: BuildArtifactAsZip::packaged.yaml
                  Capabilities: CAPABILITY_IAM
                InputArtifacts:
                  - Name: BuildArtifactAsZip
                RunOrder: 1
              - Name: ExecuteChangeSet
                ActionTypeId:
                  Category: Deploy
                  Owner: AWS
                  Provider: CloudFormation
                  Version: "1"
                Configuration:
                  ActionMode: CHANGE_SET_EXECUTE
                  RoleArn: !GetAtt CloudFormationExecutionRole.Arn
                  StackName: !Sub ${GithubRepoAndBranch}-Gamma
                  ChangeSetName: !Sub ${GithubRepoAndBranch}-ChangeSet-Gamma
                OutputArtifacts:
                  - Name: !Sub ${GithubRepoAndBranch}GammaChangeSet
                RunOrder: 2

          # !     ____  ____  ____  ____
          # !    / __ \/ __ \/ __ \/ __ \
          # !   / /_/ / /_/ / / / / / / /
          # !  / ____/ _, _/ /_/ / /_/ /
          # ! /_/   /_/ |_|\____/_____/
          # ! STAGE 5 = Prod
          # ! Rinse, repeat. Before proceeding with the Prod deployment, your pipeline has a manual approval step.
          - !If 
            - IsMasterBranch
            - Name: Prod
              # Condition: IsMasterBranch
              Actions:
                - Name: DeploymentApproval
                  ActionTypeId:
                    Category: Approval
                    Owner: AWS
                    Provider: Manual
                    Version: "1"
                  RunOrder: 1
                - Name: CreateChangeSet
                  ActionTypeId:
                    Category: Deploy
                    Owner: AWS
                    Provider: CloudFormation
                    Version: "1"
                  Configuration:
                    ActionMode: CHANGE_SET_REPLACE
                    RoleArn: !GetAtt CloudFormationExecutionRole.Arn
                    StackName: !Sub ${GithubRepoAndBranch}-Prod
                    ChangeSetName: !Sub ${GithubRepoAndBranch}-ChangeSet-Prod
                    TemplatePath: BuildArtifactAsZip::packaged.yaml
                    Capabilities: CAPABILITY_IAM
                  InputArtifacts:
                    - Name: BuildArtifactAsZip
                  RunOrder: 2
                - Name: ExecuteChangeSet
                  ActionTypeId:
                    Category: Deploy
                    Owner: AWS
                    Provider: CloudFormation
                    Version: "1"
                  Configuration:
                    ActionMode: CHANGE_SET_EXECUTE
                    RoleArn: !GetAtt CloudFormationExecutionRole.Arn
                    StackName: !Sub ${GithubRepoAndBranch}-Prod
                    ChangeSetName: !Sub ${GithubRepoAndBranch}-ChangeSet-Prod
                  OutputArtifacts:
                    - Name: !Sub ${GithubRepoAndBranch}ProdChangeSet
                  RunOrder: 3
            - !Ref AWS::NoValue


#! ██████╗ ██╗██████╗ ███████╗██╗     ██╗███╗   ██╗███████╗    ██╗ █████╗ ███╗   ███╗
#! ██╔══██╗██║██╔══██╗██╔════╝██║     ██║████╗  ██║██╔════╝    ██║██╔══██╗████╗ ████║
#! ██████╔╝██║██████╔╝█████╗  ██║     ██║██╔██╗ ██║█████╗      ██║███████║██╔████╔██║
#! ██╔═══╝ ██║██╔═══╝ ██╔══╝  ██║     ██║██║╚██╗██║██╔══╝      ██║██╔══██║██║╚██╔╝██║
#! ██║     ██║██║     ███████╗███████╗██║██║ ╚████║███████╗    ██║██║  ██║██║ ╚═╝ ██║
#! ╚═╝     ╚═╝╚═╝     ╚══════╝╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝    ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝
                                                                                  
    CodePipelineExecutionRole:
        Type: AWS::IAM::Role
        Properties:
            AssumeRolePolicyDocument:
                Version: '2012-10-17'
                Statement:
                  - 
                    Action: 
                        - 'sts:AssumeRole'
                    Effect: Allow
                    Principal:
                      Service: 
                        - codepipeline.amazonaws.com
            Path: /
            Policies:
                - PolicyName: CodePipelineAccess
                  PolicyDocument:
                    Version: '2012-10-17'
                    Statement:
                        - 
                            Effect: Allow
                            Action:
                                - 'iam:PassRole'
                                - 'lambda:InvokeFunction'
                                - 'lambda:ListFunctions'
                                - 'lambda:InvokeAsyc'
                            Resource: '*'
                - PolicyName: CodePipelineCodeAndArtifactsS3Bucket
                  PolicyDocument:
                    Version: '2012-10-17'
                    Statement:
                      - 
                        Effect: Allow
                        Action: 's3:*'
                        Resource: !Sub 'arn:aws:s3:::${BuildArtifactsBucket}/*'
                - PolicyName: CodePipelineCodeBuildAndCloudformationAccess
                  PolicyDocument:
                    Version: '2012-10-17'
                    Statement:
                      - 
                        Effect: Allow
                        Action: 
                          - 'codebuild:StartBuild'
                          - 'codebuild:BatchGetBuilds'
                        Resource: 
                          - !Sub 'arn:aws:codebuild:${AWS::Region}:${AWS::AccountId}:project/${CodeBuildProject}'
                      - 
                        Effect: Allow
                        Action: 
                          - 'cloudformation:CreateStack'
                          - 'cloudformation:DescribeStacks'
                          - 'cloudformation:DeleteStack'
                          - 'cloudformation:UpdateStack'
                          - 'cloudformation:CreateChangeSet'
                          - 'cloudformation:ExecuteChangeSet'
                          - 'cloudformation:DeleteChangeSet'
                          - 'cloudformation:DescribeChangeSet'
                          - 'cloudformation:SetStackPolicy'
                          - 'cloudformation:SetStackPolicy'
                          - 'cloudformation:ValidateTemplate'
                        Resource: 
                          - !Sub 'arn:aws:cloudformation:${AWS::Region}:${AWS::AccountId}:stack/${GithubRepoAndBranch}*/*'
                          - !Sub 'arn:aws:cloudformation:${AWS::Region}:aws:transform/Serverless-2016-10-31'

                          
#!   ██████╗ ██╗   ██╗████████╗██████╗ ██╗   ██╗████████╗███████╗
#!  ██╔═══██╗██║   ██║╚══██╔══╝██╔══██╗██║   ██║╚══██╔══╝██╔════╝
#!  ██║   ██║██║   ██║   ██║   ██████╔╝██║   ██║   ██║   ███████╗
#!  ██║   ██║██║   ██║   ██║   ██╔═══╝ ██║   ██║   ██║   ╚════██║
#!  ╚██████╔╝╚██████╔╝   ██║   ██║     ╚██████╔╝   ██║   ███████║
#!   ╚═════╝  ╚═════╝    ╚═╝   ╚═╝      ╚═════╝    ╚═╝   ╚══════╝

Outputs:
    GitHubRepositoryHttpUrl:
      Description: GitHub Git repository
      Value: !Sub https://github.com/${GithubUser}/${GithubRepo}.git

    GitHubRepositorySshUrl:
      Description: GitHub Git repository
      Value: !Sub git@github.com:${GithubUser}/${GithubRepo}.git
  
    BuildArtifactS3Bucket:
      Description: Amazon S3 Bucket for Pipeline and Build artifacts
      Value: !Ref BuildArtifactsBucket

    CodeBuildProject:
      Description: CodeBuild Project name
      Value: !Ref CodeBuildProject

    CodePipeline:
      Description: AWS CodePipeline pipeline name
      Value: !Ref Pipeline

    CodeBuildIAMRole:
      Description: CodeBuild IAM Role
      Value: !GetAtt CodeBuildServiceRole.Arn

    CloudformationIAMRole:
      Description: Cloudformation IAM Role
      Value: !GetAtt CloudFormationExecutionRole.Arn

    CodePipelineIAMRole:
      Description: CodePipeline IAM Role
      Value: !GetAtt CodePipelineExecutionRole.Arn

