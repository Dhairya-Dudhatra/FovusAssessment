All the resources are created in "us-east-1" region.
Please create these resources with exact same names.





DRIVE FOLDER ITEMS INFO:
---------------------------------------------------------------------------------------------------
|	Names                 |	Containes			
---------------------------------------------------------------------------------------------------
|   fovusfrontend	       |   Has static website code in React.js                             | 
|   dbconnectfunction         |   Lambda js code which creates an entry in table                  |
|   dynamodbstreamprocess     |   Lambda js code which gets ID and creates a VM                   |
|   script.sh		       |   Shell script which appends string and updates table and bucket. |
--------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------

RESOURCES INFO:
-------------------------------------------------------------------------------------------------------------------------------------
|           Names             |         Job                                                             |       Resources-Type      |
-------------------------------------------------------------------------------------------------------------------------------------
| fovusstaticwebsite          | Host a static website                                                   |       S3 Bucket           | 
| fovuschallengeinputbucket   | Stores script.sh and other files which will be uploaded from website.   |       S3 Bucket           |
| dbconnectfunction           | Gets information from website and passes to the lambda function.        |       API                 |
| dbconnectfunction           | Get the details from APIGateway and creates an entry in DynamoDb table  |       Lambda              |
| dynamodbstreamprocess       | Gets trigger by DynamoDB INSERT event and creates a VM                  |       Lambda              |
| appendtextdata              | Stores the data from website                                            |       DynamoDB Table      |
-------------------------------------------------------------------------------------------------------------------------------------


RESOURCES SETUP:

S3:
fovusstaticwebsite - Enable versioning
                     Enable static website hosting. "index.html" as an Index Document.
                     Copy the Build folder from the fovusfrontend folder from drive.
                     BucketPolicy:
                   -------------------------------------------------------------  
                      {                                                         
                       "Version": "2012-10-17",                                 
                       "Statement": [                                           
                         {                                                      
                             "Sid": "PublicReadGetObject",                      
                             "Effect": "Allow",                                 
                             "Principal": "*",                                  
                             "Action": "s3:GetObject",                          
                             "Resource": "arn:aws:s3:::fovusstaticwebsite/*"    
                         }                                                      
                        ]                                                       
                      }                                                         
                   ------------------------------------------------------------- 

                   Website URL : <Static-website-URL>
                   
                   

fovuschallengeinputbucket - Enable Versioning
                            Permissions -> CORS
                        -------------------------------------------------------------------------
                        [
                          {
                            "AllowedHeaders": [
                                "*"
                            ],
                            "AllowedMethods": [
                                "PUT",
                                "POST"
                            ],
                            "AllowedOrigins": [
                               <Website URL>
                            ],
                            "ExposeHeaders": []
                          }
                        ]
                        ---------------------------------------------------------------------------
                        
                        
                        
API :
		- Create a REST API (accessible outside of VPC)
		- Create Resource 
			Create an "ANY" method and attach the dbconnectfunction lambda.
			Enable CORS and Remove the Authorization.


dbconnectfunction: 
		- Make a ZIP of drive folder "dbconnectfunction".
		- Runtime - Node.js 14.x
		- Upload ZIP. Remove a layer in file tree.
		- Handler: index.handler 
		- Timeout- 10s
		- Trigger : Automatically gets setup when you connect API with lambda
		- Role JSON
		----------------------------------------------------------------------------------------
		{
		    "Version": "2012-10-17",
		    "Statement": [
			{
			    "Effect": "Allow",
			    "Action": "logs:CreateLogGroup",
			    "Resource": "arn:aws:logs:us-east-1:506640589918:*"
			},
			{
			    "Effect": "Allow",
			    "Action": [
				"logs:CreateLogStream",
				"logs:PutLogEvents"
			    ],
			    "Resource": [
				"arn:aws:logs:us-east-1:506640589918:log-group:/aws/lambda/dbconnectfunction:*"
			    ]
			},
			{
			    "Effect": "Allow",
			    "Action": [
				"dynamodb:PutItem",
				"dynamodb:Scan",
				"dynamodb:UpdateItem"
			    ],
			    "Resource": "arn:aws:dynamodb:us-east-1:506640589918:table/*"
			}
		    ]
		}
		---------------------------------------------------------------------------------------------
		


dynamodbstreamprocess:
		- Runtime - Node.js 14.x
		- Upload "index.js" from drive folder.
		- Handler: index.handler
		- Timeout- 3min
		- Trigger : DynamoDB Table "appenddatatext"
			    Batch Size = 1
			    Starting Position = Latest
		- You would need to create an extra role for VM.
		- Role JSON
		--------------------------------------------------------------------------------------------
		{
		    "Version": "2012-10-17",
		    "Statement": [
			{
			    "Sid": "VisualEditor0",
			    "Effect": "Allow",
			    "Action": [
				"iam:GetRole",
				"iam:PassRole"
			    ],
			    "Resource": "arn:aws:iam::506640589918:role/temporary-vm-access-role"
			},
			{
			    "Effect": "Allow",
			    "Action": [
				"ec2:RunInstances",
				"ec2:CreateTags",
				"ec2:DescribeInstances",
				"ec2:DescribeInstanceStatus",
				"ec2:TerminateInstances"
			    ],
			    "Resource": "*"
			},
			{
			    "Effect": "Allow",
			    "Action": [
				"dynamodb:DescribeStream",
				"dynamodb:GetRecords",
				"dynamodb:GetShardIterator",
				"dynamodb:ListStreams"
			    ],
			    "Resource": "arn:aws:dynamodb:us-east-1:506640589918:table/appendtextdata/stream/*"
			},
			{
			    "Effect": "Allow",
			    "Action": "logs:CreateLogGroup",
			    "Resource": "arn:aws:logs:us-east-1:506640589918:*"
			},
			{
			    "Effect": "Allow",
			    "Action": [
				"logs:CreateLogStream",
				"logs:PutLogEvents"
			    ],
			    "Resource": [
				"arn:aws:logs:us-east-1:506640589918:log-group:/aws/lambda/dynamodbstreamprocess:*"
			    ]
			}
		    ]
		}
		------------------------------------------------------------------------------------------------

		
			
		
                       
                        
                        
                        
                        
                        
                    
