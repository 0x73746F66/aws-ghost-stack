const AWS = require('aws-sdk')
const util = require('util')
const program = require('commander')
const co = require('co')
const prompt = require('co-prompt')
const chalk = require('chalk')

const DEFAULT_REGION = 'ap-southeast-2'

const createQueue = (queue) => {
  co(function* prompter() {
    const metadata = new AWS.MetadataService()
    let sqs, sns, iam
    if (!program.region) {
      program.region = DEFAULT_REGION
    }
    if (!program.profile) {
      const key = yield prompt(chalk.bgYellow.bold('Access Key: '))
      const secret = yield prompt.password(chalk.bgYellow.bold('Secret Access Key: '))

      AWS.config.update({
        accessKeyId: key,
        region: program.region,
        secretAccessKey: secret
      })
      sqs = new AWS.SQS()
      sns = new AWS.SNS()
      iam = new AWS.IAM()
    } else {
      AWS.config.update({
        profile: program.profile,
        region: program.region
      })
      sqs = new AWS.SQS()
      sns = new AWS.SNS()
      iam = new AWS.IAM()
    }
    let QueueName = ''
    let Name = ''
    if (typeof queue === 'string') {
      QueueName = queue
      Name = queue
    }

    iam.getUser({}, (err, data) => {
      if (err) {
        metadata.request('/latest/meta-data/iam/info/', (err, data) => {
          if (err) {
            console.log(err, err.stack)
            return
          }
          program.awsId = JSON.parse(data).InstanceProfileArn.split(':')[4]
        })
      } else {
        program.awsId = data.User.Arn.split(':')[4]
      }
      const TopicArn = `arn:aws:sns:${program.region}:${program.awsId}:${Name}`
      const Endpoint = `arn:aws:sqs:${program.region}:${program.awsId}:${Name}`
      const QueueUrl = `https://sqs.${program.region}.amazonaws.com/${program.awsId}/${Name}`
      sqs.createQueue({ QueueName }, (err, result) => {
        if (err) {
          console.log(util.inspect(err))
          return
        }
        console.log(util.inspect(result))
        sns.createTopic({ Name }, (err, result) => {
          if (err) {
            console.log(util.inspect(err))
            return
          }
          console.log(util.inspect(result))
          sns.subscribe({
            Protocol: 'sqs',
            TopicArn,
            Endpoint,
          }, (err, result) => {
            if (err) {
              console.log(util.inspect(err))
              return
            }
            console.log(util.inspect(result))
            const attributes = {
              "Version": "2008-10-17",
              "Id": `${Endpoint}/SQSDefaultPolicy`,
              "Statement": [{
                "Sid": "Sid" + new Date().getTime(),
                "Effect": "Allow",
                "Principal": {
                  "AWS": "*"
                },
                "Action": "SQS:SendMessage",
                "Resource": Endpoint,
                "Condition": {
                  "ArnEquals": {
                    "aws:SourceArn": TopicArn
                  }
                }
              }
              ]
            }
            sqs.setQueueAttributes({
              QueueUrl,
              Attributes: {
                'Policy': JSON.stringify(attributes)
              }
            }, (err, result) => {
              if (err) {
                console.log(util.inspect(err))
                return
              }
              console.log(util.inspect(result))
            })
          })
        })
      })
    })
  })
}

program.arguments('<queue>')
  .option('-p, --profile <profile>', 'The aws profile')
  .option('-r, --region <region>', 'The aws region')
  .action(createQueue)
  .parse(process.argv)
