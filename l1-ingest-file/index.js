const AWS = require("aws-sdk");
const s3 = new AWS.S3(
  process.env.localstack == "true"
    ? {
        s3ForcePathStyle: true,
        endpoint: `http://172.17.0.2:4572`
      }
    : {}
);

const dynamoDB = new AWS.DynamoDB(
  process.env.localstack == "true"
    ? {
        endpoint: `http://${process.env.LOCALSTACK_HOSTNAME}:4569`
      }
    : {}
);

exports.handler = async function(event) {
  console.log("l1-ingest-file : Starting\n");
  console.log("Env:", process.env);

  console.log("EVENT", event, "\n");
  const { name } = event.Records[0].s3.bucket;
  const { key } = event.Records[0].s3.object;
  const s3Params = {
    Bucket: name,
    Key: key
  };
  console.log("S3 parameters set, about to call s3 bucket\n");
  const s3Data = await s3.getObject(s3Params).promise();
  console.log("File Data:", s3Data, "\n");

  // Insert colour if new, send to sns if exist already innit.

  return "l1-ingest-file : Finished\n";
};
