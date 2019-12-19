package com.trivadis.request.processor;

public class App {
    public static void main(String[] args) {
        int responseSize = getArgValue( args, 0, 96 );
        int requestCount = getArgValue( args, 1, 32 );
        int processingThreadCount = getArgValue( args, 2, 2 );
        new Executor( responseSize, requestCount, processingThreadCount );
    }

    private static int getArgValue(String[] args, int index, int defaultValue) {
        try {
            return Integer.parseInt( args[index] );
        } catch ( RuntimeException e ) {
            return defaultValue;
        }
    }
}
