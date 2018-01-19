package com.mycompany.consumer;

import com.amazonaws.services.kinesis.clientlibrary.exceptions.InvalidStateException;
import com.amazonaws.services.kinesis.clientlibrary.exceptions.ShutdownException;
import com.amazonaws.services.kinesis.clientlibrary.exceptions.ThrottlingException;
import com.amazonaws.services.kinesis.clientlibrary.interfaces.IRecordProcessorCheckpointer;
import com.amazonaws.services.kinesis.clientlibrary.interfaces.v2.IRecordProcessor;
import com.amazonaws.services.kinesis.clientlibrary.lib.worker.ShutdownReason;
import com.amazonaws.services.kinesis.clientlibrary.types.InitializationInput;
import com.amazonaws.services.kinesis.clientlibrary.types.ProcessRecordsInput;
import com.amazonaws.services.kinesis.clientlibrary.types.ShutdownInput;
import com.amazonaws.services.kinesis.model.InvalidArgumentException;
import com.amazonaws.services.kinesis.model.Record;

import java.nio.charset.Charset;
import java.nio.charset.CharsetDecoder;
import java.util.ArrayList;
import java.util.List;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.events.KinesisEvent;
import com.amazonaws.services.lambda.runtime.events.KinesisEvent.KinesisEventRecord;
import com.mycompany.lambda.KinesisLambdaStreamsProcessor;
import com.mycompany.lambda.RawEventsProcessorLambda;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

/**
 * @author Diogo Aurelio (diogoaurelio)
 */
public class KinesisConsumerProcessor implements IRecordProcessor
{

    private static final Log LOG = LogFactory.getLog(KinesisConsumerProcessor.class);

    private String kinesisShardId;
    private Boolean retryableStrategy;
    private LambdaFunc lambdaRecordsProcessorClass;

    // Backoff and retry settings
    private static final long BACKOFF_TIME_IN_MILLIS = 1000L;
    private static final int NUM_RETRIES = 10;
    // Checkpoint w/ X frequency
    private static final long CHECKPOINT_INTERVAL_MILLIS = 60000L;
    private long nextCheckpointTimeInMillis;

    private final CharsetDecoder decoder = Charset.forName("UTF-8").newDecoder();

    public KinesisConsumerProcessor()
    {
        this(null);
    }

    public KinesisConsumerProcessor( final LambdaFunc lambda )
    {
            this(lambda, null);
    }


    public KinesisConsumerProcessor( final LambdaFunc lambda, final Boolean retryable ) throws InvalidArgumentException
    {
        if ( lambda == null )
        {
            throw new InvalidArgumentException("Need to specify which lambda you want to invoke");
        } else
        {
            this.lambdaRecordsProcessorClass = lambda;
        }
        if ( retryable == null)
        {
            this.retryableStrategy = false;
        }
    }



    @Override
    public void initialize( final InitializationInput initializationInput )
    {
        kinesisShardId = initializationInput.getShardId();
        String seqNumber = initializationInput.getExtendedSequenceNumber().getSequenceNumber();
        LOG.info("Initializing record processor for shardId: " + kinesisShardId + " and sequence number: "+ seqNumber);
    }

    @Override
    public void processRecords( final ProcessRecordsInput processRecordsInput ) {
        LOG.info("Processing " + processRecordsInput.getRecords().size() + " records from shardId " + kinesisShardId);

        List<Record> records = processRecordsInput.getRecords();
        KinesisEvent kinesisEvent = mockKinesisEvent(records);
        Context mockContext = new MockLambdaContext();

        switch (lambdaRecordsProcessorClass)
        {
            case RAW_EVENTS_PROCESSOR:
                System.out.println("Invoking Raw events Lambda function");
                KinesisLambdaStreamsProcessor lambda = new RawEventsProcessorLambda();
                lambda.handleRequest( kinesisEvent, mockContext );

                break;

            case S3_ROUTER:
                System.out.println("Invoking S3 router Lambda function");
                break;

            case EVENTS_PROCESSOR:
                System.out.println("Invoking S3 router Lambda function");
                break;

            default:
                System.out.println("No lambda specified, nothing to do!");
                break;
        }

        if (System.currentTimeMillis() > nextCheckpointTimeInMillis)
        {
            checkpoint(processRecordsInput.getCheckpointer());
            nextCheckpointTimeInMillis = System.currentTimeMillis() + CHECKPOINT_INTERVAL_MILLIS;
        }
    }

    private KinesisEvent mockKinesisEvent( List<Record> records)
    {
        KinesisEvent kinesisEvent = new KinesisEvent();
        kinesisEvent.setRecords(mockKinesisRecords(records));

        return kinesisEvent;
    }

    private List<KinesisEventRecord> mockKinesisRecords(List<Record> records)
    {
        List<KinesisEventRecord> kinesisEventRecords = new ArrayList<>();
        for ( Record record: records)
        {
            KinesisEvent.Record kRecord = new KinesisEvent.Record();
            kRecord.setData(record.getData());
            kRecord.setPartitionKey(record.getPartitionKey());
            kRecord.setApproximateArrivalTimestamp(record.getApproximateArrivalTimestamp());
            kRecord.setEncryptionType(record.getEncryptionType());
            kRecord.setSequenceNumber(record.getSequenceNumber());

            KinesisEventRecord eventRecord = new KinesisEventRecord();
            eventRecord.setKinesis(kRecord);
            kinesisEventRecords.add(eventRecord);
        }
        return kinesisEventRecords;
    }


    private void checkpoint(IRecordProcessorCheckpointer checkpointer)
    {
        LOG.info("Checkpointing shard " + kinesisShardId);
        for (int i = 0; i < NUM_RETRIES; i++)
        {
            try
            {
                checkpointer.checkpoint();
            } catch ( ShutdownException se)
            {
                LOG.error("Caught shutdown exception, skiping checkpoint!", se);
                break;
            } catch (ThrottlingException te)
            {
                if ( i >= (NUM_RETRIES -1))
                {
                    LOG.error("Checkpoint failed after " + (i+1) + " attempts.", te);
                    break;
                } else
                {
                    LOG.info("Transient issue when checkpointing - attempt " + (i + 1) + " of "
                            + NUM_RETRIES, te);
                }
            } catch ( InvalidStateException e)
            {
                // This indicates an issue with the DynamoDB table (check for table, provisioned IOPS).
                LOG.error("Cannot save checkpoint to the DynamoDB table used by the Amazon Kinesis Client Library.", e);
                break;
            }
            try
            {
                Thread.sleep(BACKOFF_TIME_IN_MILLIS);
            } catch (InterruptedException ie)
            {
                LOG.debug("Interrupted sleep", ie);
            }
        }
    }


    @Override
    public void shutdown( ShutdownInput shutdownInput ) {
        IRecordProcessorCheckpointer checkpointer = shutdownInput.getCheckpointer();
        ShutdownReason shutdownReason = shutdownInput.getShutdownReason();

    }




}
