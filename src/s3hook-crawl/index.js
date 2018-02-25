const AWS = require('aws-sdk')

const DEFAULT_REGION = 'ap-southeast-2'
const QueueName = 'crawl'

AWS.config.update({
  accessKeyId: process.env.ACCESS_KEY_ID,
  region: process.env.AWS_REGION,
  secretAccessKey: process.env.SECRET_ACCESS_KEY
})

const sts = new AWS.STS()
let TopicArn, sendMessage
exports.handler = (event, context) => {
  context.callbackWaitsForEmptyEventLoop = false

  sts.getCallerIdentity({}, (err, data) => {
    if (err) {
      console.log("Error", err)
    } else {
      TopicArn = `arn:aws:sns:${DEFAULT_REGION}:${data.Account}:${QueueName}`
      sendMessage = (Message) => new Promise((ok, fail) => {
        const sns = new AWS.SNS()
        sns.publish({
          Message: typeof Message === 'string' ? Message : JSON.stringify(Message),
          TopicArn,
        }, (err, data) => {
          if (err) {
            err instanceof Error ? fail(err) : fail(new Error(err))
          } else {
            ok(data)
          }
        })
      })
      const tasks = []
      if ('Records' in event) {
        for (const record of event.Records) {
          const key = decodeURIComponent(record.s3.object.key.replace(/\+/g, ' '))
          console.log('received: ', key)

          if (key.indexOf('.html') === -1) {
            console.log('Invalid file extension for this script, expected .html')
          } else {
            console.log(`Sending [${key}] to ${TopicArn}`)
            tasks.push(sendMessage(record))
          }
        }
      }
      Promise.all(tasks)
        .then(context.succeed)
        .catch(err => {
          console.error(err)
          context.fail(err)
        })
    }
  })
}
