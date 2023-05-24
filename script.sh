set -e

#Fetching DynamoDB Item
id="$1"
if item=$(aws dynamodb get-item --region us-east-1 --table-name appendtextdata --key "{\"id\": {\"S\": \"${id}\" }}"); then
        echo "Item Download in EC2."	
else
        echo " Problem Occured Accessing DynamoDB Table"
        exit 1
fi

#Extracting Fiels Values
input_path=$(echo $item | awk -F ':' '/input_file_path/{print $6}' | cut -d '}' -f 1 | sed 's/"//g' | sed 's/\s//g' )
strng=$(echo $item | awk -F ':' '/input_text/{print $4}' | cut -d '}' -f 1 | sed 's/"//g' )


#Downloading input file from S3
aws s3 cp s3://${input_path} ~/
filename=$(echo $input_path | cut -d '/' -f 2)
bucket=$(echo $input_path | cut -d '/' -f 1)

sudo chmod 755 /home/ubuntu/${filename}

#Appending Input_text to file
echo $strng >> /home/ubuntu/${filename}
echo "String appended Successfully"

#Uploading This File to S3 Back
aws s3 cp /home/ubuntu/${filename} s3://${bucket}/output.txt
echo "File uploaded Sucessfully back to S3."

newpath="${bucket}/output.txt" 

#Updating Entry in DynamoDB
if (aws dynamodb update-item --table-name appendtextdata --region us-east-1 --key "{\"id\": {\"S\": \"${id}\" }}" --update-expression 'SET #nf= :nv' --expression-attribute-names '{"#nf": "output_file_path"}' --expression-attribute-values "{\":nv\": {\"S\": \"${newpath}\" }}"); then
        echo "DynamoDB Table Updated"
else
        echo "Error in Updating DynamoDB Table"
        exit 1
fi

#Terminating the Instance
curl -s http://169.254.169.254/latest/meta-data/instance-id | xargs aws ec2 terminate-instances --region us-east-1 --instance-ids
