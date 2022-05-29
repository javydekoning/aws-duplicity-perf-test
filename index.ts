#!/usr/bin/env node
import 'source-map-support/register';
import { App, Stack, StackProps } from 'aws-cdk-lib';
import { Construct } from 'constructs';
import {
  aws_ec2 as ec2,
  aws_iam as iam,
  aws_s3_assets as s3a,
  aws_s3 as s3,
} from 'aws-cdk-lib';

const app = new App();

const instancesToTest = [
  // 'c6g.large',
  'm5zn.large',
  // 'c6i.large',
  'c6i.xlarge',
  'r6i.large',
];

class BackuptestingStack extends Stack {
  constructor(scope: Construct, id: string, props?: StackProps) {
    super(scope, id, props);

    // pre-existing bucket to store results
    // it also has the dataset stored
    const bucket = s3.Bucket.fromBucketName(this, 'myBucket', 'javydekoning');

    //Upload perf script to s3
    const perfSript = new s3a.Asset(this, 'perf', {
      path: './perf.sh',
    });

    //create ec2 instance role to write to bucket. 
    const role = new iam.Role(this, 'TempRole', {
      assumedBy: new iam.ServicePrincipal('ec2.amazonaws.com'),
    });
    perfSript.grantRead(role);
    bucket.grantReadWrite(role);
    role.addManagedPolicy(
      iam.ManagedPolicy.fromManagedPolicyArn(this, 'ssm','arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore')
    )
    //temp testing vpc.
    const vpc = new ec2.Vpc(this, 'vpc', {
      maxAzs: 1,
    });

    const userData = ec2.UserData.forLinux();
    userData.addCommands(
      `yum update -y
amazon-linux-extras install epel -y
export PREF=$(date +%Y%m%d-%s)
export FILE=$PREF.$(curl http://169.254.169.254/latest/meta-data/instance-type).results.txt
aws s3 cp ${perfSript.s3ObjectUrl} - | sh > $FILE
aws s3 cp ./$FILE s3://javydekoning/backuptesting/results/$FILE
poweroff`
    );

    const disk = {
      deviceName: '/dev/xvda',
      volume: ec2.BlockDeviceVolume.ebs(200, {
        deleteOnTermination: true,
        volumeType: ec2.EbsDeviceVolumeType.GP2,
      }),
    };

    instancesToTest.forEach((i) => {
      let name = i.replace('.', ''); // c6i.large -> c6ilarge
      let instanceType = new ec2.InstanceType(i);
      let cpu =
        instanceType.architecture == 'x86_64'
          ? ec2.AmazonLinuxCpuType.X86_64
          : ec2.AmazonLinuxCpuType.ARM_64;

      // Set latest Amazon Linux 2 AMI. 
      let machineImage = new ec2.AmazonLinuxImage({
        cpuType: cpu,
        kernel: ec2.AmazonLinuxKernel.KERNEL5_X,
        generation: ec2.AmazonLinuxGeneration.AMAZON_LINUX_2,
      });

      new ec2.Instance(this, name, {
        instanceType,
        machineImage,
        vpc,
        userData,
        role,
        blockDevices: [disk],
      });
    });
  }
}

new BackuptestingStack(app, 'TestStack', {
  //env: {region: 'us-east-1'}
});
