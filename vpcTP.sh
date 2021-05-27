#!/bin/sh
echo "Creation d'un vpc ...."

idvpc=`aws ec2 create-vpc --cidr-block 10.0.0.0/16 --output text --query 'Vpc.VpcId'`
#Nom VPC
aws ec2 create-tags --resources "$idvpc" --tags Key=Name,Value="MonVPC"

echo "Vpc MonVPC id = $idvpc crée"

echo "création des sous reseaux LAN et DMZ"

idLAN=`aws ec2 create-subnet --vpc-id $idvpc --cidr-block 10.0.1.0/24 --output text --query 'Subnet.SubnetId'`
#Nom sous reseau LAN
aws ec2 create-tags --resources "$idLAN" --tags Key=Name,Value="LAN"

echo "sous reseau LAN id = $idLAN crée"

idDMZ=`aws ec2 create-subnet --vpc-id $idvpc --cidr-block 10.0.2.0/24 --output text --query 'Subnet.SubnetId'`
#Nom sous reseau DMZ
aws ec2 create-tags --resources "$idDMZ" --tags Key=Name,Value="DMZ"

echo "sous reseau DMZ id = $idDMZ crée"

echo "autorisation des adresses ip public dans mon sous reseau DMZ ...."

$resIP=`aws ec2 modify-subnet-attribute --subnet-id "$idDMZ" --map-public-ip-on-launch --output text`

echo "Maintenant les instances du sous reseau DMZ ont des adresses IP public"


echo " Creation d'un internet gateway et l'attacher a MonVPC ..."

idGW=`aws ec2 create-internet-gateway --output text --query 'InternetGateway.InternetGatewayId'`

#nom  internet gateway
aws ec2 create-tags --resources "$idGW" --tags Key=Name,Value="MonGW"

$resGW=`aws ec2 attach-internet-gateway --vpc-id $idvpc --internet-gateway-id $idGW --output text`

echo " internet gateway d'id -> $idGW est bien attaché a MonVPC"

echo " Creation d'une table de routage pour DMZ ....."

idTRDMZ=`aws ec2 create-route-table --vpc-id $idvpc --output text --query 'RouteTable.RouteTableId'`
#Nom table de routage DMZ
aws ec2 create-tags --resources "$idTRDMZ" --tags Key=Name,Value="TRDMZ"

echo " table de routage pour DMZ crée avec id -> $idTRDMZ "

echo "creation route pour tout le traffic internet ..."

$resR1=`aws ec2 create-route --route-table-id $idTRDMZ --destination-cidr-block 0.0.0.0/0 --gateway-id $idGW --output text`

echo " route créé"

echo " association de notre table de routage pour DMZ a notre sous reseau DMZ ...."

$resAssoc=`aws ec2 associate-route-table  --subnet-id $idDMZ --route-table-id $idTRDMZ --output text`

echo "association effectué"

echo " creation d'un adresse ip public pour mon passerelle NAT ......"

idAllocIp=`aws ec2 allocate-address --domain vpc --network-border-group us-east-2 --output text --query 'AllocationId'`

echo " adresse ip public crée"

echo "Creation d'un passerelle NAT et y associer l'adresse ip public ...."

idNAT=`aws ec2 create-nat-gateway --subnet-id $idDMZ --allocation-id $idAllocIp --output text --query 'NatGateway.NatGatewayId'`

#nom  NAT gateway
aws ec2 create-tags --resources "$idNAT" --tags Key=Name,Value="MonNAT"

echo "Passerelle NAT is -> $idNAT crée"



echo " Creation d'une table de routage pour LAN ....."

idTRLAN=`aws ec2 create-route-table --vpc-id $idvpc --output text --query 'RouteTable.RouteTableId'`
#Nom table de routage LAN
aws ec2 create-tags --resources "$idTRLAN" --tags Key=Name,Value="idTRLAN"

echo " table de routage pour LAN crée avec id -> $idTRLAN "


echo "creation route pour notre table de routage NAT"

$resR2=`aws ec2 create-route --route-table-id $idTRLAN --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $idNAT --output text`

echo " route créé"


echo " association de notre table de routage pour LAN a notre sous reseau LAN ...."

$resAssoc2=`aws ec2 associate-route-table  --subnet-id $idLAN --route-table-id $idTRLAN --output text`

echo "association effectué"



echo "Création d'un groupe de sécurité et activer le ssh ....."

idGroupSec=`aws ec2 create-security-group --group-name SSHAccess --description "ssh access" --vpc-id $idvpc --output text --query 'GroupId'`

$resSSH=`aws ec2 authorize-security-group-ingress --group-id $idGroupSec --protocol tcp --port 22 --cidr 0.0.0.0/0 --output text`


echo " groupe de sécurité avec ssh  id $idGroupSec crée "

echo " lancer deux instances , une dans LAN et un autre dans DMZ ....."

idInstances1=`aws ec2 run-instances --image-id ami-0b9064170e32bde34 --count 1 --instance-type t2.micro --key-name sir2soir --security-group-ids $idGroupSec --subnet-id $idLAN --output text --query 'Instances[0].InstanceId'`

idInstances2=`aws ec2 run-instances --image-id ami-0b9064170e32bde34 --count 1 --instance-type t2.micro --key-name sir2soir --security-group-ids $idGroupSec --subnet-id $idDMZ --output text --query 'Instances[0].InstanceId'`


echo " les deux instance sont lancés respectivement dans LAN et DMz avec idInstancesLAN -> $idInstances1 et idInstancesDMZ -> $idInstances2"


echo "-------Configuration terminée---------------"







