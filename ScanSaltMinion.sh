#!/bin/bash

#Path2File
IPsearched='here.ip'
ResultOK='serversOK'
ResultNOK='serversNOK'
noCheck='CheckSaltMinion_noCheckHosts.txt'
SCAN='scan.txt'
Amazon='Amazon'
Master='SaltMaster'
Excluded="`date +"%m%d%y"`"."ExcludedOK"

#We look for available servers on the networks that we can login with SSH:
sudo nmap -p22 -oG /tmp/$SCAN  PUTyourRANGofNETWORKS > /dev/null
cat /tmp/$SCAN |grep open |awk '{print $2}' >> /tmp/$IPsearched

#Remove the excluded hosts
for hostsDEL in $(cat $noCheck); do
  sed -i /"$hostsDEL"$/d /tmp/$IPsearched
done

#Check if the servers have salt-minion:
for ipp in $(cat /tmp/$IPsearched); do
  if [ `timeout 30s ssh -oConnectTimeout=30 -oBatchMode=yes -oStrictHostKeyChecking=no $ipp 'sudo ps -ef |grep -c salt-minion'` -gt "2" ]; then
    echo `timeout 30s ssh -oConnectTimeout=30 -oBatchMode=yes -oStrictHostKeyChecking=no $ipp sudo hostname`" - $ipp - OK" >> /tmp/$ResultOK
  else
    echo `timeout 30s ssh -oConnectTimeout=30 -oBatchMode=yes -oStrictHostKeyChecking=no $ipp sudo hostname`" - $ipp - NOK" >> /tmp/$ResultNOK
  fi
done

#Check with Salt-Master on port 4505
ssh -o StrictHostKeyChecking=no SaltMasterServer sudo lsof -i :4505 | awk '{print $2}' FS="->" | awk '{print $1}' FS=":" > /tmp/$Master

##Excluded from first
for hostsMASTER in $(cat /tmp/$Master); do
  if [[ $hostsMASTER == *PARTofHOSTNAME* ]]; then
    cat /tmp/$ResultOK |grep $hostsMASTER"\ "| cut -d. -f 1 > /dev/null
    if [ `echo $?` = "1" ]; then
      echo $hostsMASTER | cut -d. -f 1 >> /tmp/$Excluded
    fi
  else
    cat /tmp/$ResultOK |grep $hostsMASTER"\ " > /dev/null
    if [ `echo $?` = "1" ]; then
      if [[ $hostsMASTER == *NETWORKamazon* ]]; then
        echo $hostsMASTER >> /tmp/$Amazon
      fi
    else
      echo $hostsMASTER >> /tmp/$Excluded
    fi
  fi
done

#custom name result files
minionOK=`wc -l /tmp/$ResultOK |awk {'print $1'}`
minionNOK=`wc -l /tmp/$ResultNOK |awk {'print $1'}`
SaltMaster=`wc -l /tmp/$Master |awk {'print $1'}`
AmazonON=`wc -l /tmp/$Amazon |awk {'print $1'}`
mv /tmp/$ResultOK /tmp/`date +"%m%d%y"`"."$ResultOK"."$minionOK
mv /tmp/$ResultNOK /tmp/`date +"%m%d%y"`"."$ResultNOK"."$minionNOK
mv /tmp/$Master /tmp/`date +"%m%d%y"`"."$Master"."$SaltMaster
mv /tmp/$Amazon /tmp/`date +"%m%d%y"`"."$Amazon"."$AmazonON

#Sending report and files to mail
HowMany=`wc -l /tmp/$IPsearched |awk {'print $1'}`
echo -e "$HowMany scanned servers, $minionOK with salt-minion running and $minionNOK without salt-minion\nSalt-Master says: $SaltMaster salt-minion started (include Amazon and special "network")" | mutt -s "AutoCheck Salt-Minion" PUTyour@mail.HERE -a /tmp/`date +"%m%d%y"`"."$ResultOK"."$minionOK /tmp/`date +"%m%d%y"`"."$ResultNOK"."$minionNOK /tmp/$IPsearched /tmp/`date +"%m%d%y"`"."$Master"."$SaltMaster /tmp/`date +"%m%d%y"`"."$Amazon"."$AmazonON /tmp/$Excluded $noCheck

#Delete all the files created
sudo rm /tmp/$SCAN
rm /tmp/$IPsearched
rm /tmp/`date +"%m%d%y"`"."$ResultOK"."$minionOK
rm /tmp/`date +"%m%d%y"`"."$ResultNOK"."$minionNOK
rm /tmp/`date +"%m%d%y"`"."$Master"."$SaltMaster
rm /tmp/`date +"%m%d%y"`"."$Amazon"."$AmazonON
rm /tmp/$Excluded
