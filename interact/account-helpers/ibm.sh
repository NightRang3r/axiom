#!/bin/bash

AXIOM_PATH="$HOME/.axiom"
source "$AXIOM_PATH/interact/includes/vars.sh"

appliance_name=""
appliance_key=""
appliance_url=""
token=""
region=""
provider=""
size=""
email=""
cpu=""
username=""
ibm_cloud_api_key=""

function getUsernameAPIkey {

email=$(cat ~/.bluemix/config.json  | grep Owner | cut -d '"' -f 4)
username=$(ibmcloud sl user list | grep $email | tr -s ' ' | cut -d ' ' -f 2)
accountnumber=$(ibmcloud sl user list | grep $email | tr -s ' ' | cut -d ' ' -f 1)
token=$(ibmcloud sl user detail $accountnumber --keys  | grep APIKEY | tr -s ' ' | cut -d ' ' -f 2)
if [ -z "$token" ]
then
echo -e -n "${Green}Create an IBM Classic API key (for packer) here: https://cloud.ibm.com/iam/apikeys (required): \n>> ${Color_Off}"
read token
while [[ "$token" == "" ]]; do
	echo -e "${BRed}Please provide a IBM Cloud Classic API key, your entry contained no input.${Color_Off}"
	echo -e -n "${Green}Please enter your IBM Cloud Classic API key (required): \n>> ${Color_Off}"
	read token
done
fi
}

function apikeys {

echo -e -n "${Green}Create an IBM Cloud API Key (for ibmcli) here: https://cloud.ibm.com/iam/apikeys (required): \n>> ${Color_Off}"
read ibm_cloud_api_key
while [[ "$ibm_cloud_api_key" == "" ]]; do
	echo -e "${BRed}Please provide a IBM Cloud API key, your entry contained no input.${Color_Off}"
	echo -e -n "${Green}Please enter your IBM Cloud API key (required): \n>> ${Color_Off}"
	read ibm_cloud_api_key
done
ibmcloud login --apikey=$ibm_cloud_api_key
getUsernameAPIkey
}

function specs {

echo -e -n "${Green}Please enter your default region: (Default 'dal13', press enter) \n>> ${Color_Off}"
read region
if [[ "$region" == "" ]]; then
	echo -e "${Blue}Selected default option 'dal13'${Color_Off}"
	region="dal13"
fi

echo -e -n "${Green}Please enter your default size: (Default '2048', press enter) \n>> ${Color_Off}"
read size
if [[ "$size" == "" ]]; then
	echo -e "${Blue}Selected default option '2048'${Color_Off}"
  size="2048"
fi

echo -e -n "${Green}Please enter amount of CPU Cores: (Default '2', press enter) \n>> ${Color_Off}"
read cpu
if [[ "$cpu" == "" ]]; then
  echo -e "${Blue}Selected default option '2'${Color_Off}"
  cpu="2"
fi
}

prompt=$(tput setaf 2; echo "Choose how to authenticate to IBM Cloud:" )
PS3="$prompt "
types=("SSO" "Username & Password" "API Keys" "Quit")
 select i in "${types[@]}"; do
   case $i in
   "SSO")
     echo "Attempting to authenticate with SSO!"
     ibmcloud login --sso
     getUsernameAPIkey
     specs
     break
     ;;
  "username and password")
     ibmcloud login
     specs
     break
     ;;
  "API keys")
     apikeys
     specs
     break
     ;; 
  "Quit")
     echo "User requested exit"
     exit
     ;;
   *) echo "invalid option $REPLY";;
 esac
done

echo -e -n "${Green}Please enter your GPG Recipient Email (for encryption of boxes): (optional, press enter) \n>> ${Color_Off}"
read email

echo -e -n "${Green}Would you like to configure connection to an Axiom Pro Instance? Y/n (Must be deployed.) (optional, default 'n', press enter) \n>> ${Color_Off}"
read ans

if [[ "$ans" == "Y" ]]; then
    echo -e -n "${Green}Enter the axiom pro instance name \n>> ${Color_Off}"
    read appliance_name

    echo -e -n "${Green}Enter the instance URL (e.g \"https://pro.acme.com\") \n>> ${Color_Off}"
    read appliance_url

    echo -e -n "${Green}Enter the access secret key \n>> ${Color_Off}"
    read appliance_key 
fi

data="$(echo "{\"do_key\":\"$token\",\"ibm_cloud_api_key\":\"$ibm_cloud_api_key\",\"region\":\"$region\",\"provider\":\"ibm\",\"default_size\":\"$size\",\"cpu\":\"$cpu\",\"username\":\"$username\",\"base_image_id\":\"$base_image_id\",\"appliance_name\":\"$appliance_name\",\"appliance_key\":\"$appliance_key\",\"appliance_url\":\"$appliance_url\", \"email\":\"$email\"}")"

echo -e "${BGreen}Profile settings below: ${Color_Off}"
echo $data | jq
echo -e "${BWhite}Press enter if you want to save these to a new profile, type 'r' if you wish to start again.${Color_Off}"
read ans

if [[ "$ans" == "r" ]];
then
    $0
    exit
fi

echo -e -n "${BWhite}Please enter your profile name (e.g 'personal', must be all lowercase/no specials)\n>> ${Color_Off}"
read title

if [[ "$title" == "" ]]; then
    title="personal"
    echo -e "${Blue}Named profile 'personal'${Color_Off}"
fi

echo $data | jq > "$AXIOM_PATH/accounts/$title.json"
echo -e "${BGreen}Saved profile '$title' successfully!${Color_Off}"
$AXIOM_PATH/interact/axiom-account $title
