##Region####
aws_region="ap-south-1"
###############
###### Create a VPC using Cloudformation
AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws cloudformation create-stack --stack-name vpcstack --region $aws_region --template-body file://$3/ec2.yaml > /dev/null
AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws cloudformation wait stack-create-complete --stack-name vpcstack --region $aws_region
stackstatus=$(AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws cloudformation describe-stacks --stack-name vpcstack --region aws_region | jq -r .Stacks[].StackStatus)
if [ "${stackstatus}" == "CREATE_COMPLETE" ]
then
        a=Success
else
        a=Failure
fi


###### Create custom policy
AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws iam create-policy --policy-name restrictpolicy --policy-document file://$3/restrictpolicy.json --region $aws_region

###### Find Account id
accid=`AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws sts get-caller-identity --output text | cut -f1`

###### Attach policy to group and user

AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonRDSFullAccess --group-name studentlab
AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws iam attach-group-policy --policy-arn arn:aws:iam::$accid:policy/restrictpolicy  --group-name studentlab
AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/EC2InstanceConnect --group-name studentlab

### Verification###
#policy1=arn:aws:iam::aws:policy/AmazonEC2FullAccess
policy1="$polarn"

policy2=`AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws iam list-attached-group-policies --group-name studentlab |grep -Po  '(arn:)[^"]+'`
if [ $? -eq 0 ]; then
    echo "Success"
else
    echo "Failure"
fi

