# Kinesis Streams Lambda local setup

This repo contains example local setup of Kinesis streams integration with Lambda. 
That is, you are able to emulate production cloud environment by running docker containers, as well as the required code that mimics the main tasks that AWS runs behind the scenes when it invokes Lambda functions.

Furthermore on AWS stack, we have also included DynamoDB and S3 docker containers. 

Last but not least, we have included a Postgres docker container, since it fits one of our internal use cases. 


# Running locally


## Docker env

We are using the following docker containers:

- [Postgres official Docker container v 9.6](https://hub.docker.com/_/postgres/)
- [Kinesalite: Kinesis Docker container](vsouza/kinesis-local)
- [scality s3server Docker container to mock AWS S3](https://hub.docker.com/r/scality/s3server/)
- [DynamoDB Docker](https://hub.docker.com/r/dwmkerr/dynamodb/)

As previously mentioned, we have emulated the main parts behind the scenes when AWS invokes Lambdas functions to consume a given batch of events from Kinesis. 
That also includes providing a synthetic Kinesis Consumer Library (KCL) (which consists of the main tasks that in reality are done behind the scenes by AWS service), which invokes the main Lambda function that we handle Kinesis Records.

However, in order for the KCL to work properly, it needs DynamoDB. Thus, besides a Kinesis docker container, we've also added a dynamoDB docker container.

Last but not least, a common use case for you lambda might be to enrich some events, and push them to an S3 bucket. Thus, we've also included S3 mock docker container, to make it easier for anyone to also mock AWS S3 locally.

### Test running RawEventsProcessorLambda


To test running the lambda function "RawEventsProcessorLambda", please start by launching the full Docker containers environment:

```
cd docker/bootstrapEnv
bash runDocker.sh
```

In case you have docker installed with sudo, do rather:

```
cd docker/bootstrapEnv
bash runDocker.sh --s=sudo
```

This will go ahead and download docker images (if you do not have them already locally), and start the previously listed containers.

Note: we are not persisting any data on Docker env on purpose, so you can customize freely your dev environment.


Additionally, we also use some bash scripts to preconfigure the docker environment:

- Create on your machine a fake AWS profile used to communicate with local AWS S3 docker and AWS Kinesis docker
- Create a bucket on AWS S3 docker (check in docker/s3/runDocker.sh script to see what the latest default bucket name is).
- In case you have included migration scripts (in /src/main/resources/sql/), they will also be run to create any required tables in postgres, as well dummy values.


After the previous script finishes (might take a minute or so, due to the S3 setup), we need to start by running the migrations for postgres.

The sql scripts to create and fill the tables are in "/src/main/resources/sql/".

If you want to check if the scripts have successfully ran, you can:

```
export PGPASSWORD=mysecretpassword
psql -h localhost -d streamingdb -p 15432 --user postgres
psql> select * from <your-table> limit 10;
psql> \q;
```

Note that postgres docker has it's port mapped to your localhost port "15432", rather than "5432".

We are ready to see all moving pieces together! Let us enable the synthetic Kinesis AWS Lambda consumer. In one terminal window enter and located at the root of this project:
```
source mediarithmics_lambda/bin/activate
python src/lambdas/mediarithmics_ingest/local_app.py
```

In another terminal window - again still located at the root of this project - start generating events:
```
cd docker/common
bash generateRecordsKinesis.sh
```

This will randomly generate records with distinct UUIDs, for 20 distinct user_accounts. This should be your goto in order to customize the fake data generated.



Last but not least, we can run locally our RawEventsProcessorLambda. Kinesis docker does not support CBOR, thus you are required to change the way the Java Kinesis Client Library is consuming from Kinesis.
Either in your IDE or in terminal set environment variable 'AWS_CBOR_DISABLE=true'. For example:

```
export AWS_CBOR_DISABLE=true
```


That's it!

