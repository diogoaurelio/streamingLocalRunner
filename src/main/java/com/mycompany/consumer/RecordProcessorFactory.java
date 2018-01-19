package com.mycompany.consumer;

import com.amazonaws.services.kinesis.clientlibrary.interfaces.v2.IRecordProcessor;
import com.amazonaws.services.kinesis.clientlibrary.interfaces.v2.IRecordProcessorFactory;

/**
 * @author Diogo Aurelio (diogoaurelio)
 */
public class RecordProcessorFactory implements IRecordProcessorFactory
{

    public RecordProcessorFactory()
    {
        super();
    }

    @Override
    public IRecordProcessor createProcessor()
    {
        return new KinesisConsumerProcessor();
    }
}
