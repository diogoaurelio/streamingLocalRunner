package com.mycompany.localrunner;

import com.amazonaws.AmazonClientException;
import com.amazonaws.auth.profile.ProfileCredentialsProvider;
import com.amazonaws.client.builder.AwsClientBuilder.EndpointConfiguration;
import com.amazonaws.services.dynamodbv2.AmazonDynamoDB;
import com.amazonaws.services.dynamodbv2.AmazonDynamoDBClientBuilder;
import com.amazonaws.services.kinesis.AmazonKinesis;
import com.amazonaws.services.kinesis.AmazonKinesisClientBuilder;
import com.amazonaws.services.kinesis.clientlibrary.interfaces.v2.IRecordProcessorFactory;
import com.amazonaws.services.kinesis.clientlibrary.lib.worker.InitialPositionInStream;
import com.amazonaws.services.kinesis.clientlibrary.lib.worker.KinesisClientLibConfiguration;
import com.amazonaws.services.kinesis.clientlibrary.lib.worker.Worker;
import com.amazonaws.services.kinesis.model.ResourceNotFoundException;
import com.mycompany.consumer.KinesisConsumerProcessorManager;

import java.net.InetAddress;
import java.util.UUID;

/**
 * @author Diogo Aurelio (diogoaurelio)
 */
public class RawEventsProcessorLambdaRunner {

    private static ProfileCredentialsProvider credentialsProvider;
    private static EndpointConfiguration kinesisEndpointConfig;
    private static EndpointConfiguration dynamoDbEndpointConfig;

    // this is a local profile that uses mock credentials to interact
    // with local AWS docker containers
    private static final String AWS_PROFILE = "my-mock-profile";
    private static final String AWS_REGION = "eu-central-1";
    private static final String APP_NAME = "KinesisRawEventsProcessor";
    private static final InitialPositionInStream SAMPLE_APPLICATION_INITIAL_POSITION_IN_STREAM =
            InitialPositionInStream.LATEST;

    private static void init()
    {
        try
        {
            credentialsProvider = new ProfileCredentialsProvider(AWS_PROFILE);

        } catch (Exception e)
        {
            throw new AmazonClientException("Cannot load the credentials from the credential profiles file. "
                    + "Please make sure that your credentials file is at the correct "
                    + "location (~/.aws/credentials), that it is in valid format, "
                    + "and that you run the docker bootstrap scripts that configure the "
                    + "mock credentials.", e);
        }
        kinesisEndpointConfig = new EndpointConfiguration("http://localhost:4567", AWS_REGION);
        dynamoDbEndpointConfig = new EndpointConfiguration("http://localhost:8765", AWS_REGION);

    }

    private static void deleteResources() {
        // Delete the stream
        AmazonKinesis kinesis = AmazonKinesisClientBuilder.standard()
                .withCredentials(credentialsProvider)
                .withRegion(AWS_REGION)
                .withEndpointConfiguration(kinesisEndpointConfig)
                .build();

        System.out.printf("Deleting the Amazon Kinesis stream used by the sample. Stream Name = %s.\n",
                APP_NAME);
        try {
            kinesis.deleteStream(APP_NAME);
        } catch (ResourceNotFoundException ex) {
            // The stream doesn't exist.
        }

        // Delete the table
        AmazonDynamoDB dynamoDB = AmazonDynamoDBClientBuilder.standard()
                .withCredentials(credentialsProvider)
                .withRegion(AWS_REGION)
                .withEndpointConfiguration(dynamoDbEndpointConfig)
                .build();
        System.out.printf("Deleting the Amazon DynamoDB table used by the Amazon Kinesis Client Library. Table Name = %s.\n",
                APP_NAME);
        try {
            dynamoDB.deleteTable(APP_NAME);
        } catch (com.amazonaws.services.dynamodbv2.model.ResourceNotFoundException ex) {
            // The table doesn't exist.
            System.out.println("DynamoDB Table " + APP_NAME + " does not seem to exist");
        }
    }

    public static void main(String[] args)
    {
        System.out.println("Loading AWS credentials...");
        init();
        System.out.println("Initiallizing runners...");

        String workerId = "someWorker";
        try {
            workerId = InetAddress.getLocalHost().getCanonicalHostName() + ":" + UUID.randomUUID();
        } catch (java.net.UnknownHostException e) {}

        final KinesisClientLibConfiguration kinesisClientLibConfiguration =
                new KinesisClientLibConfiguration(APP_NAME,
                        APP_NAME,
                        credentialsProvider,
                        workerId);
        kinesisClientLibConfiguration.withInitialPositionInStream(SAMPLE_APPLICATION_INITIAL_POSITION_IN_STREAM);

        final IRecordProcessorFactory recordProcessorFactory = new KinesisConsumerProcessorManager();
        final Worker worker = new Worker.Builder()
                .recordProcessorFactory(recordProcessorFactory)
                .config(kinesisClientLibConfiguration)
                .build();

        System.out.printf("Running %s to process stream %s as worker %s...\n",
                APP_NAME,
                APP_NAME,
                workerId);

        int exitCode = 0;
        try {
            worker.run();
        } catch (Throwable t) {
            System.err.println("Caught throwable while processing data.");
            t.printStackTrace();
            exitCode = 1;
        }
        System.exit(exitCode);

    }
}
