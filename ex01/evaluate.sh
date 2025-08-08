Total=0
aws_region="ap-south-1"
#AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws configure --region $aws_region
vpcid=`AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws ec2 describe-vpcs --filters Name=tag:Name,Values=Lab-VPC |jq -r .Vpcs[].VpcId`
sg=`AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2   aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpcid" --query "SecurityGroups[*].[GroupName]" --output text | grep -i -w "db-sg"`
if [ -z ${sg} ];
        then
                SgStatus="Failure";
				SgOberv="You have not created db-sg security group in Lab-VPC";
                SgFeedback="Follow Task1 [Configure Security] instuctions to configure DB security";
                SgScore=0;
                Total=`expr $Total + $SgScore`;
                #Total=$(echo "$Total + $SgScore" | bc);

        else
                SgStatus="Success";
				SgOberv="You have successfully created $sg security group in Lab-VPC";
                SgFeedback="Task1 [Configure Security] completed successfully";
                SgScore=20;
                Total=`expr $Total + $SgScore`;
                #Total=$(echo "$Total + $SgScore" | bc);

fi 

httpport=`AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpcid" | jq -r --arg sg "$sg" '.SecurityGroups[] | select (.GroupName ==$sg) | .IpPermissions[].FromPort' |grep 3306`
if [ "$httpport" != "3306" ]
        then
                PortStatus="Failure";
				PortOberv="You have not configured security group to allow access to MySQL database"; 
                PortFeedback="Follow Task1 [Configure Security] instructions to configure MySQL database port";
                PortScore=0;
                Total=`expr $Total + $PortScore`;
                #Total=$(echo "$Total + $PortScore" | bc);

        else
		appsgid=$(AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2  aws ec2 describe-security-groups --filters Name=ip-permission.from-port,Values=80 | jq -r .SecurityGroups[].GroupId | wc -l)
		sgpair=$(AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2  aws ec2 describe-security-groups --filters Name=ip-permission.from-port,Values=3306 | jq -r .SecurityGroups[].GroupId | wc -l)
		 if ([ $appsgid -ge 1 ] && [ $sgpair -ge 1 ])

		then
	                PortStatus="Success";
					PortOberv="You have successfully configured application to access MySQL database";
        	        PortFeedback="Task1 [Configure Security] completed successfully";
                	PortScore=20;
               		Total=`expr $Total + $PortScore`;
                	#Total=$(echo "$Total + $PortScore" | bc);
		else
			PortStatus="Partial Completed";
			PortOberv="MySQL database access is granted in security group $sg, but not to App-SG[${appsgid}]";
                        PortFeedback="Follow Task1 [Configure Security] instructions to properly configure DB security";
                        PortScore=15;
                        Total=`expr $Total + $PortScore`;
                        #Total=$(echo "$Total + $PortScore" | bc);
		fi
fi

dbinstances=$(AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws rds describe-db-instances | jq -r .DBInstances[].DBInstanceIdentifier)
nodbinstances=$(AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws rds describe-db-instances | jq -r .DBInstances[].DBInstanceIdentifier | wc -l)
if [ "${nodbinstances}" -gt 1 ]
	then
		StateStatus="Partial";
		StateOberv="You have created multiple DBinstances[$dbinstances].";
                StateFeedback="Follow Task2 [Create an Amazon RDS database] lab instructions and create only one RDS instance as specified";
                StateScore=10;
				dbpass=0;
                Total=`expr $Total + $StateScore`;
                #Total=$(echo "$Total + $StateScore" | bc);
else
state=`AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws rds describe-db-instances | jq -r '.DBInstances[].DBInstanceStatus'`
if [ "$state" != "available" ]
        then
                StateStatus="Failure";
				StateOberv="No running DB instance in Lab-VPC";
                StateFeedback="Follow Task2 [Create an Amazon RDS database] lab instructions and create an RDS database";
                StateScore=0;
				dbpass=0;
                Total=`expr $Total + $StateScore`;
                #Total=$(echo "$Total + $StateScore" | bc);

        else
		dbinstanceid=`AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws rds describe-db-instances | jq -r .DBInstances[].DBInstanceIdentifier`
                StateStatus="Success";
				StateOberv="You have successfully created an RDS database [$dbinstanceid] in the Lab-VPC";
                StateFeedback="Task2 [Create an Amazon RDS database] completed successfully";
                StateScore=20;
				dbpass=1;
                Total=`expr $Total + $StateScore`;
                #Total=$(echo "$Total + $StateScore" | bc);
fi
fi

if [ $dbpass -eq 1 ]; then
dbsgid=$(AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2  aws ec2 describe-security-groups --filters Name=ip-permission.from-port,Values=3306 | jq -r .SecurityGroups[].GroupId)
dbsgid1=$(AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws rds describe-db-instances | jq -r .DBInstances[].VpcSecurityGroups[].VpcSecurityGroupId)

if [ -z "${dbsgid}" ]
then
DBGroupStatus="Failure";
				DBGroupOberv="You have not created security group";
                DBGroupFeedback="Follow Task1 [ Configure Security ] instructions to create and configure security group";
                DBGroupScore=0;
				DBGpass=0;
                Total=`expr $Total + $DBGroupScore`;
else
		DBGroupStatus="Success";
		DBGroupOberv="You have attached security group [$dbsgid] to database instance[$dbinstanceid]";
                DBGroupFeedback="Task2 [Create an Amazon RDS database] completed successfully";
                DBGroupScore=20;
				DBGpass=1;
                Total=`expr $Total + $DBGroupScore`;
fi 
else
    DBGroupStatus="Failure";
				DBGroupOberv="You have not created security group";
                DBGroupFeedback="Follow Task1 [ Configure Security ] instructions to create and configure security group";
                DBGroupScore=0;
				DBGpass=0;
                Total=`expr $Total + $DBGroupScore`;
fi
			
   if [ $DBGpass -eq 1 ]; then 
	if [ -z $sgpair ]
	then
	WebsiteStatus="Failure"
					WebsiteOberv="Webserver is not running or database is not configure properly";
        			WebsiteFeedback="Follow the Task1 [ Configure Security] and Task2 [ Create an Amazon RDS database] instructions to configure application with RDS database"
        			WebsiteScore=0
        			Total=`expr $Total + $WebsiteScore`
        			#Total=$(echo "$Total + $WebsiteScore" | bc)
	 else
		publicip=`AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws ec2 describe-instances --filters "Name=vpc-id,Values=$vpcid" "Name=instance-state-name,Values=running" |jq -r .Reservations[].Instances[].PublicIpAddress`
		websitestatus=`curl  -Is http://$publicip | egrep -i HTTP | cut -f2,3,4 -d " "`
		if [ -z $dbinstances ]; then
		WebsiteStatus="Failure"
					WebsiteOberv="Webserver is not running or database is not configure properly";
        			WebsiteFeedback="Follow the Task3 [Test the application] instructions to configure Database settings in the application"
        			WebsiteScore=0
        			Total=`expr $Total + $WebsiteScore`
        			#Total=$(echo "$Total + $WebsiteScore" | bc)
		elif echo "${websitestatus}" | grep -o 'Not Found' > /dev/null;
			then
        			WebsiteStatus="Falilure"
					WebsiteOberv="The Webserver is not running";
        			WebsiteFeedback="Check if EC2 instance [Webserver] exist and running"
        			WebsiteScore=0
        			Total=`expr $Total + $WebsiteScore`
        			#Total=$(echo "$Total + $WebsiteScore" | bc)

		elif echo "${websitestatus}" | grep -o 'OK' > /dev/null;
			then
				instanceid=$(AWS_ACCESS_KEY_ID=$1 AWS_SECRET_ACCESS_KEY=$2 aws ec2 describe-instances --filters "Name=vpc-id,Values=$vpcid" "Name=instance-state-name,Values=running" |jq -r .Reservations[].Instances[].InstanceId)
        			WebsiteStatus="Success"
					WebsiteOberv="You have successfully configure and accessed RDS Database from EC2 instance (http://$publicip)";
        			WebsiteFeedback="Task3 [Test the application] completed successfully";
        			WebsiteScore=20
       				Total=`expr $Total + $WebsiteScore`
        			#Total=$(echo "$Total + $WebsiteScore" | bc)
		else
        			WebsiteStatus="Failure"
					WebsiteOberv="Webserver is not running or database is not configure properly";
        			WebsiteFeedback="Follow the Task3 [Test the application] instructions to configure Database settings in the application"
        			WebsiteScore=0
        			Total=`expr $Total + $WebsiteScore`
        			#Total=$(echo "$Total + $WebsiteScore" | bc)

		fi
		
	fi
	else
	WebsiteStatus="Failure"
					WebsiteOberv="Webserver is not running or database is not configure properly";
        			WebsiteFeedback="Follow the Task3 [Test the application] instructions to configure Database settings in the application"
        			WebsiteScore=0
        			Total=`expr $Total + $WebsiteScore`
        			#Total=$(echo "$Total + $WebsiteScore" | bc)


fi
	



        #Result
        Result='@responsestart@ \n
        {\n
                "Exercise": " Amazon RDS Database" ,\n
                "TestCases": [{ \n
                "Name": "Task1: Configure Security", \n
                "Status": "'$SgStatus'", \n
                "Skill": "Beginner", \n
                "Score": "'$SgScore'% ",\n
                "Feedback": "'$SgFeedback'",\n
                "Observation": "'$SgOberv'",\n
                "ConsoleOutput": ""\n
                },\n
                {\n
                "Name": "Task1: Configure Security", \n
                "Status": "'$PortStatus'", \n
                "Skill": "Beginner", \n
                "Score": "'$PortScore'% ",\n
                "Feedback": "'$PortFeedback' ",\n
                "Observation": "'$PortOberv'",\n
                "ConsoleOutput": ""\n
                },\n
                {\n
                "Name": "Task2: Create an Amazon RDS Database", \n
                "Status": "'$StateStatus'", \n
                "Skill": "Beginner", \n
                "Score": "'$StateScore'% ",\n
                "Feedback": "'$StateFeedback' ",\n
                "Observation": "'$StateOberv'",\n
                "ConsoleOutput": ""\n
                },\n
                {\n
                "Name": "Task2: Create an Amazon RDS Database", \n
                "Status": "'$DBGroupStatus'", \n
                "Skill": "Beginner", \n
                "Score": "'$DBGroupScore'% ",\n
                "Feedback": "'$DBGroupFeedback' ",\n
                "Observation": "'$DBGroupOberv'",\n
                "ConsoleOutput": ""\n
                },\n
                {\n
                "Name": "Task3: Test the Application", \n
                "Status": "'$WebsiteStatus'", \n
                "Skill": "Beginner", \n
                "Score": "'$WebsiteScore'% ",\n
                "Feedback": "'$WebsiteFeedback' ",\n
                "Observation": "'$WebsiteOberv'",\n
                "ConsoleOutput": ""\n
                }],\n


                "TotalScore":"'$Total'%"\n
        }\n
                 @responseend@'
                echo -e $Result

