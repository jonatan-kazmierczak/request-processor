package com.trivadis.request.processor;

import java.io.IOException;
import java.io.PrintWriter;
import java.io.UncheckedIOException;
import java.math.BigInteger;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.time.Duration;
import java.time.Instant;
import java.util.*;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.IntStream;

public class Executor {
    private final static int REPORT_VALUES_COUNT = 3;

    private final int responseSize;
    private final int requestCount;
    private final int processingThreadCount;
    private final BlockingQueue<Request> requests;
    private final BlockingQueue<Response> responses;
    private final ExecutorService executorService;
    private final ArrayList<Long> responseTimes;
    private final AtomicInteger requestCounter = new AtomicInteger(  );

    public Executor(int responseSize, int requestCount, int processingThreadCount) {
        this.responseSize = responseSize;
        this.requestCount = requestCount;
        this.processingThreadCount = processingThreadCount;
        requests = new ArrayBlockingQueue<>( 1, false );
        responses = new ArrayBlockingQueue<>( processingThreadCount, false );
        responseTimes = new ArrayList<>( requestCount );

        new Thread( this::processResponse, "processResponse" ).start();
        new Thread( this::generateRequests, "generateRequests" ).start();
        executorService = Executors.newFixedThreadPool( processingThreadCount );
        IntStream.range( 0, processingThreadCount )
                .forEach( i -> executorService.execute( this::processRequest ) );
    }

    protected void generateRequests() {
        for ( int i = 0; i < requestCount; i++ ) {
            try {
                requests.put( new Request( i, Instant.now() ) );
            } catch ( InterruptedException e ) {
                e.printStackTrace();
            }
        }
        System.out.println( "finished generateRequests " + Thread.currentThread().getName() );
    }

    protected void processRequest() {
        while (true) {
            try {
                Request request = requests.take();
                request.time = Instant.now();
                responses.put( createResponseAndGarbage( request ) );
                requestCounter.getAndIncrement();
            } catch ( InterruptedException e ) {
                break;
            }
        }
        System.out.println( "finished processRequest " + Thread.currentThread().getName() );
    }

    private Response createResponseAndGarbage(Request request) {
        String valueStr = "";
        for ( int i = 0; i < responseSize; i++ ) {
            valueStr += (char) (32 + (request.index + i) % 95);
        }
        BigInteger hashCode = createHashCodeAndGarbage( valueStr );
        Instant start = request.time;
        Instant end = Instant.now();
        Duration duration = Duration.between( start, end );
        return new Response( request.index, start, end, duration, valueStr, hashCode );
    }

    private BigInteger createHashCodeAndGarbage(String s) {
        BigInteger hashCode = BigInteger.ZERO;
        for (int v : s.toCharArray()) {
            hashCode = hashCode.multiply( BigInteger.valueOf( 31 ) )
                    .add( BigInteger.valueOf( v ) )
                    .mod( BigInteger.valueOf( 1_000_000_000_000_000_000L ) );
        }
        return hashCode;
    }

    protected void processResponse() {
        while (!responses.isEmpty() || requestCounter.get() < requestCount) {
            try {
                Response response = responses.take();
                long duration = response.duration.toMillis();
                responseTimes.add( duration );
            } catch ( InterruptedException e ) {
                e.printStackTrace();
            }
        }
        executorService.shutdownNow();
        System.out.println( "finished processResponse " + Thread.currentThread().getName() );
        dumpStatistics();
    }

    private void dumpStatistics() {
        try ( PrintWriter out = new PrintWriter( Files.newBufferedWriter( Paths.get("response_times.txt") ) ) ) {
            for ( Long time : responseTimes ) {
                out.println( time );
            }
        } catch ( IOException e ) {
            throw new UncheckedIOException( e );
        }
    }


    static class Request {
        final int index;
        Instant time;

        Request(int index, Instant time) {
            this.index = index;
            this.time = time;
        }
    }

    static class Response {
        final int index;
        final Instant start;
        final Instant end;
        final Duration duration;
        final String valueStr;
        final BigInteger hashCode;

        Response(int index, Instant start, Instant end, Duration duration, String valueStr, BigInteger hashCode) {
            this.index = index;
            this.start = start;
            this.end = end;
            this.duration = duration;
            this.valueStr = valueStr;
            this.hashCode = hashCode;
        }

        @Override
        public String toString() {
            return "Response{" +
                    "index=" + index +
                    ", start=" + start +
                    ", end=" + end +
                    ", duration=" + duration +
                    ", valueStr='" + valueStr + '\'' +
                    ", hashCode=" + hashCode +
                    '}';
        }
    }
}
