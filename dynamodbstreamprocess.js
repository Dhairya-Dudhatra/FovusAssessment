

console.log('Loading function');

exports.handler = async (event, context) => {
    
    if(event.Records[0].eventName == 'INSERT')
    {
      const id = event.Records[0].dynamodb.Keys.id.S;
      //const userData = base64.fromByteArray(new TextEncoder().encode(fileName));
      const AWS = require('aws-sdk');
      const ec2 = new AWS.EC2();
      //console.log(id);
      //AWS.config.update({region: 'us-east-1'});
      // 
      
      const userData = `#!/bin/bash
      sudo apt update && sudo apt install awscli -y\nid=${id}\naws s3 cp s3://fovuschallengeinputbucket/script.sh /home/ubuntu\nchmod +x /home/ubuntu/script.sh\nsudo chown ubuntu:ubuntu /home/ubuntu/script.sh\nsudo -u ubuntu /home/ubuntu/script.sh ${id}`;
      const params = {
        ImageId: 'ami-007855ac798b5175e',
        InstanceType: 't2.micro',
        MinCount: 1,
        MaxCount: 1,
        UserData: Buffer.from(userData).toString('base64'),
        TagSpecifications: [
        {
          ResourceType: "instance",
          Tags: [
          {
            Key: "Name",
            Value: "Temp-EC2-Instance"
          }
          ]
        }
        ],
        BlockDeviceMappings: [
          {
            DeviceName: '/dev/sda1',
            Ebs: {
              VolumeSize: 8,
              VolumeType: 'gp2'
            }
          }
        ],
        IamInstanceProfile: {
            Arn: 'arn:aws:iam::506640589918:instance-profile/temporary-vm-access-role'
        }
      };
      
      try {
        const data = await ec2.runInstances(params).promise();
        console.log(`Instance created: ${data.Instances[0].InstanceId}`);
      } catch (err) {
        console.log(err);
      }
    }

    return `Successfully processed ${event.Records.length} records.`;
};

