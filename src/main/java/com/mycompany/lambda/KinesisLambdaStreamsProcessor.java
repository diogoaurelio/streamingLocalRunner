package com.mycompany.lambda;

import com.amazonaws.services.kinesis.model.Record;
import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.events.KinesisEvent;

/**
 * @author Diogo Aurelio (diogoaurelio)
 */
public interface KinesisLambdaStreamsProcessor extends LambdaStreamsProcessor
{
    void processSingleRecord( Record record );

    public Void handleRequest(KinesisEvent kinesisEvent, Context context);
}
