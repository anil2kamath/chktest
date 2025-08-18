##Region####
aws_region="ap-south-1"
#Terminate RDS Service
for rdsname in $(AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws rds describe-db-instances --query 'DBInstances[].DBInstanceIdentifier' --output text --region $aws_region)

do
	echo "Process of RDS"
	AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws rds delete-db-instance --db-instance-identifier $rdsname  --skip-final-snapshot --region $aws_region >>/dev/null 
	AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws rds wait db-instance-deleted --db-instance-identifier $rdsname --region $aws_region >>/dev/null
	echo "Terminating DB IDentifier $rdsname"
done	

for instid in $(AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws ec2 describe-instances --query "Reservations[*].Instances[*].[InstanceId]" --output text --region $aws_region)
 do
   AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws ec2 terminate-instances --instance-ids $instid --region $aws_region
   AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws ec2 wait instance-terminated --instance-ids $instid --region $aws_region
done
#######################e
echo "Instance Terminated"
##############################################
vpcid=$(AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws ec2 describe-vpcs --query 'Vpcs[*].VpcId' --output text --region $aws_region)

for igw in $(AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws ec2 describe-internet-gateways --query 'InternetGateways[?Attachments[].State].InternetGatewayId' --output text --region $aws_region)
do
  echo "IGW Deleting"
AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws ec2 detach-internet-gateway --internet-gateway-id $igw --vpc-id $vpcid --region $aws_region
AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws ec2 delete-internet-gateway --internet-gateway-id $igw --region $aws_region
done

################################################
echo "subnet del"
###### delete subnet ############################
subnets=$(AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws ec2 --region ${aws_region} describe-subnets --filters Name=vpc-id,Values=${vpcid} | jq -r .Subnets[].SubnetId)
echo ${subnets}
	  if [ "${subnets}" != "null" ]; then
		for subnet in ${subnets}; do
		  echo "Deleting subnet ${subnet}"
		  AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws ec2 --region ${aws_region} delete-subnet --subnet-id ${subnet}
		done
	  fi
#####################################################
###### delete Security Group
sg=$( AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws ec2 describe-security-groups --region ${aws_region}  | jq -r '.SecurityGroups[].GroupId')
echo ${sg}
	for rsg in $sg ; do
        ip_perm=$( AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws ec2 --region $aws_region describe-security-groups --output json --group-ids $rsg --query "SecurityGroups[0].IpPermissions")
	AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws ec2 --region $aws_region revoke-security-group-ingress --group-id $rsg --ip-permissions "$ip_perm"

	done
    echo "Revoke sg"


###### delete Security Group
sg=$( AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws ec2 describe-security-groups  | jq -r '.SecurityGroups[].GroupId')
counter=0
for i in $sg ; do
    # Check it's default security group
    sg_name=$(AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws ec2 describe-security-groups --group-ids ${i} --query 'SecurityGroups[].GroupName'  --output text)
    # Ignore default security group
    if [ "$sg_name" = 'default' ] || [ "$sg_name" = 'Default' ] || [ "$sg_name" = "Web-SG" ]; then
        continue
    fi

    echo "    delete Security group of $sg"

 AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws ec2 delete-security-group --group-id $i > /dev/null
  let counter=$counter+1
done


###### Delete cloudformation stack
AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws cloudformation delete-stack --stack-name vpcstack
#AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws cloudformation wait stack-delete-complete --stack-name vpcstack 
AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws cloudformation wait stack-delete-complete --stack-name vpcstack
stackstatus=$(AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws cloudformation list-stacks |jq -r '.StackSummaries[] | "\(.StackStatus) \(.StackName)"' | grep CREATE_COMPLETE)
if [ -z "$stackstatus" ]
then
         a=Success
else
         a=Failure
fi



###### Find and detach previous policies
for oldpolicy in $(AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws iam list-attached-group-policies --group-name studentlab |grep -Po  '(arn:)[^"]+');
do
AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws iam detach-group-policy --group-name studentlab --policy-arn $oldpolicy
done

##### Delete Custom Policy ######
accid=`AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws sts get-caller-identity --output text | cut -f1`

AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws iam delete-policy --policy-arn arn:aws:iam::$accid:policy/EC2-RDS

###Verification###
policy=`AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws iam list-attached-group-policies --group-name studentlab | jq -r '.AttachedPolicies[]'`
echo $policy

if [ -z "$policy" -a "$a" == "Success" ]
then
      echo "success"
else
      echo "failure"
fi



