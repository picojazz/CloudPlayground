#!/bin/sh

#instances
rs1=`aws ec2 terminate-instances --instance-ids $1`

rs2=`aws ec2 terminate-instances --instance-ids $2`

#security

rs3=`aws ec2 delete-security-group --group-id $7`

#gateway

rs4=`aws ec2 detach-internet-gateway --internet-gateway-id $3 --vpc-id $6`

rs5=`aws ec2 delete-internet-gateway --internet-gateway-id $3`

rs6=`aws ec2 delete-nat-gateway --nat-gateway-id $8`

#route table
rs10=`aws ec2 delete-route-table --route-table-id $9`
rs11=`aws ec2 delete-route-table --route-table-id $10`

#subnet

rs7=`aws ec2 delete-subnet --subnet-id $4`

rs8=`aws ec2 delete-subnet --subnet-id $5`

#vpc

rs9=`aws ec2 delete-vpc --vpc-id $6`


echo "--------------vpc supprimé-------------"
