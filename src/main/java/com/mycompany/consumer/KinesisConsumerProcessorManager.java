package com.mycompany.consumer;

import com.amazonaws.ClientConfiguration;
import com.amazonaws.auth.AWSCredentialsProvider;
import com.amazonaws.services.kinesis.AmazonKinesis;
import com.amazonaws.services.kinesis.AmazonKinesisClientBuilder;
import com.amazonaws.services.kinesis.clientlibrary.interfaces.v2.IRecordProcessor;
import com.amazonaws.services.kinesis.clientlibrary.interfaces.v2.IRecordProcessorFactory;
import com.amazonaws.services.kinesis.model.*;

import java.util.ArrayList;
import java.util.List;


/**
 * Utility class to run locally application
 *
 * @author Diogo Aurelio (diogoaurelio)
 */
public class KinesisConsumerProcessorManager implements IRecordProcessorFactory
{

    private LambdaFunc lambda;
    private String region;
    private AWSCredentialsProvider credentials;
    private ClientConfiguration config;
    private AmazonKinesis client;

    public KinesisConsumerProcessorManager()
    {
        this(LambdaFunc.RAW_EVENTS_PROCESSOR);
    }

    public KinesisConsumerProcessorManager( final LambdaFunc lambda )
    {
        this(lambda, null);
    }


    public KinesisConsumerProcessorManager( final LambdaFunc lambda, final String region )
    {
        this(lambda, region, null);
    }

    public KinesisConsumerProcessorManager( final LambdaFunc lambda, final String region, final AWSCredentialsProvider credentials )
    {
        this(lambda, region, credentials, null);
    }

    public KinesisConsumerProcessorManager( final LambdaFunc lambda, final String region, final AWSCredentialsProvider credentials, final ClientConfiguration config )
    {
        this.lambda = lambda;
        this.region = region;
        this.credentials = credentials;
        this.config = config;
        init();
    }


    private void init()
    {
        AmazonKinesisClientBuilder clientBuilder = AmazonKinesisClientBuilder.standard();
        clientBuilder.setRegion(this.region);
        if (credentials != null)
        {
            clientBuilder.setCredentials(this.credentials);
        }
        if (config != null)
        {
            clientBuilder.setClientConfiguration(config);
        }

        this.client = clientBuilder.build();
    }

    /**
     * Note: streams returned by listStreams can be in one of the following states:
     * [CREATING, ACTIVE, UPDATING, DELETING]
     *
     */
    public List<String> listKinesisStreams()
    {
        ListStreamsRequest listStreamsRequest = new ListStreamsRequest();

        //listStreamsRequest.setLimit(limit);
        ListStreamsResult listStreamsResult = client.listStreams(listStreamsRequest);
        List<String> streamNames = listStreamsResult.getStreamNames();
        while (listStreamsResult.getHasMoreStreams())
        {
            if (streamNames.size() > 0) {
                listStreamsRequest.setExclusiveStartStreamName(streamNames.get(streamNames.size() - 1));
            }
            listStreamsResult = client.listStreams(listStreamsRequest);
            streamNames.addAll(listStreamsResult.getStreamNames());
        }
        return streamNames;
    }


    public List<Shard> getShards( final String streamName )
    {
        DescribeStreamRequest describeStreamRequest = new DescribeStreamRequest();
        describeStreamRequest.setStreamName( streamName );
        List<Shard> shards = new ArrayList<>();
        String exclusiveStartShardId = null;
        do {
            describeStreamRequest.setExclusiveStartShardId( exclusiveStartShardId );
            DescribeStreamResult describeStreamResult = client.describeStream( describeStreamRequest );
            shards.addAll( describeStreamResult.getStreamDescription().getShards() );
            if ( describeStreamResult.getStreamDescription().getHasMoreShards() && shards.size() > 0 ) {
                exclusiveStartShardId = shards.get(shards.size() - 1).getShardId();
            } else {
                exclusiveStartShardId = null;
            }
        } while ( exclusiveStartShardId != null );
        return shards;
    }

    public void createStream( final String streamName, final int streamSize )
    {
        CreateStreamRequest createStreamRequest = new CreateStreamRequest();
        createStreamRequest.setStreamName(streamName);
        createStreamRequest.setShardCount(streamSize);

        client.createStream( createStreamRequest );
        DescribeStreamRequest describeStreamRequest = new DescribeStreamRequest();
        describeStreamRequest.setStreamName(streamName);

        long startTime = System.currentTimeMillis();
        long endTime = startTime + ( 10 * 60 * 1000 );
        while ( System.currentTimeMillis() < endTime ) {
            try {
                Thread.sleep(20 * 1000);
            }
            catch ( Exception e ) {}

            try
            {
                DescribeStreamResult describeStreamResponse = client.describeStream(describeStreamRequest);
                String streamStatus = describeStreamResponse.getStreamDescription().getStreamStatus();
                if ( streamStatus.equals( "ACTIVE" ) ) {
                    break;
                }
                //
                // sleep for one second
                //
                try {
                    Thread.sleep( 1000 );
                }
                catch ( Exception e ) {}
            }
            catch (ResourceNotFoundException e ) {}
        }
        if ( System.currentTimeMillis() >= endTime ) {
            throw new RuntimeException( "Stream " + streamName + " never went active" );
        }
    }

    @Override
    public IRecordProcessor createProcessor() {
        return new KinesisConsumerProcessor(lambda);
    }
}
