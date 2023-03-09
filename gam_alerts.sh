#The goal of this script is to investigate each email reported as spam in a Google Alerts without having
#to get delegate access on a user's mailbox
#The email will not be downloaded if the user deleted it from his trash/spam folder
#The following applications are needed to run this script : 
#1. jq - brew install jq
#2. GAMADV - https://github.com/taers232c/GAMADV-XTD3
#3. gyb - https://github.com/GAM-team/got-your-back

loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )
current_date=$(echo -e "$( date +%Y-%m-%d\ )  ${1}")

#get the alert Id and the creation date | remove the headers from output
gam_output=$(/Users/$loggedInUser/bin/gamadv-xtd3/gam config csv_output_header_filter "createTime,alertId" csv_output_row_filter 'metadata.status:regex:"NOT_STARTED",source:regex:"Gmail phishing"' print alerts  | awk '{if(NR>1)print}')


# Initialize the array
my_array=()

# Use a loop to read each line of the variable into the array
while read -r line; do
  my_array+=("$line")
done <<<"$gam_output"

#create a selectable menu with each line of $gam_output
select option in ${my_array[@]}
do
	break
done

#trim the selection made above to only keep the alertId
option=$(echo $option | cut -d, -f1)

#generate a json with the content of the alert
json_output=$(/Users/$loggedInUser/bin/gamadv-xtd3/gam info alert $option formatjson)

#run a gyb command to download each emails reported by users. Email will be stored in a .eml file to inspect using an offline mail client
mkdir "/Users/$loggedInUser/Downloads/GoogleAlert_${option}_${current_date}"
cd "/Users/$loggedInUser/Downloads/GoogleAlert_${option}_${current_date}"

#use jq to only keep the needed information to run the gyb command. 
json_output=$(/opt/homebrew/opt/jq/bin/jq -r '.data.messages[] | "\(.messageId) \(.recipient)"' <<< "$json_output")

echo $json_output | while read -r messageId recipient; do
	/Users/$loggedInUser/bin/gyb/gyb --email $recipient --search "rfc822msgid:$messageId" --spam-trash --service-account
done