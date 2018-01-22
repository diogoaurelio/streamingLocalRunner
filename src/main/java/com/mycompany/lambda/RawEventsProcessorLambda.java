package com.mycompany.lambda;

import com.amazonaws.services.kinesis.model.Record;
import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.KinesisEvent;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;


import java.util.List;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.Charset;
import java.nio.charset.CharsetDecoder;

/**
 * A demo lambda function for example purposes
 *
 * TODO: enforce proper stats!
 *
 * @author Diogo Aurelio (diogoaurelio)
 */
public class RawEventsProcessorLambda implements RequestHandler<KinesisEvent, Void>, KinesisLambdaStreamsProcessor
{

    private static final Log LOG = LogFactory.getLog(RawEventsProcessorLambda.class);
    private final CharsetDecoder decoder = Charset.forName("UTF-8").newDecoder();
    private static final int NUM_RETRIES = 10;

    @Override
    public Void handleRequest(KinesisEvent kinesisEvent, Context context) {
        int count = 0;
        for (KinesisEvent.KinesisEventRecord record: kinesisEvent.getRecords())
        {
            count ++;
            System.out.println("Partition key is: " + record.getKinesis().getPartitionKey());
            System.out.println("Sequence number is: " + record.getKinesis().getSequenceNumber());
            processSingleRecord(record.getKinesis());

        }
        System.out.println("Finished processing '" + count + "' kinesis raw record(s)");
        return null;
    }


    @Override
    public void processSingleRecord(Record record) {
        // TODO Add your own record processing logic here

        String data = null;
        try {
            // For this app, we interpret the payload as UTF-8 chars.
            data = decoder.decode(record.getData()).toString();
            System.out.println("Record data is: " + data);

            LOG.info(record.getSequenceNumber() + ", " + record.getPartitionKey() + ", " + data);
        } catch (NumberFormatException e) {
            LOG.info("Record does not match sample record format. Ignoring record with data: " + data);
        } catch (CharacterCodingException e) {
            LOG.error("Malformed data: " + data, e);
        }
    }

}
