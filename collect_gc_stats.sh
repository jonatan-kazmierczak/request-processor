#!/bin/bash
#
# Author: Jonatan Kazmierczak (Jonatan at Son-of-God.info)
#

# define variables
STATS_DIR=stats
RESPONSE_SIZE=50000
RESPONSE_COUNT=99
THREAD_COUNT=3
JAVA_APP="-jar build/libs/request-processor.jar $RESPONSE_SIZE $RESPONSE_COUNT $THREAD_COUNT"
RESPONSE_TIMES_FILE=response_times.txt
# Path to java command from OpenJDK build including Shenandoah GC - i.e. AdoptOpenJDK
JAVA_CMD=/opt2/jdk-13.0.1+9/bin/java
# Path to java command from OpenJDK with OpenJ9 VM
JAVA_J9_CMD=/opt2/jdk-13.0.1+9_openj9/bin/java
# Path to java command from Zing VM
JAVA_ZING_CMD=/opt2/zing-jdk11.0.0-19.10.1.0-3/bin/java

echo "-- Java GC Performance Statistics Collector --"
echo "Please make sure, that you are not running it in virtualized environment (i.e. Docker) and that your CPU runs on a constant frequency"
echo

$JAVA_CMD -version
echo

OUT_FILE=$STATS_DIR/gc.txt

mkdir -p $STATS_DIR

# HotSpot

echo -n vm=HotSpot,gc=Serial, > $OUT_FILE
/usr/bin/time $JAVA_CMD -XX:+UseSerialGC $JAVA_APP  2>>$OUT_FILE
mv $RESPONSE_TIMES_FILE $STATS_DIR/Serial.csv

echo -n vm=HotSpot,gc=Parallel, >> $OUT_FILE
/usr/bin/time $JAVA_CMD -XX:+UseParallelGC $JAVA_APP  2>>$OUT_FILE
mv $RESPONSE_TIMES_FILE $STATS_DIR/Parallel.csv

echo -n vm=HotSpot,gc=G1, >> $OUT_FILE
/usr/bin/time $JAVA_CMD -XX:+UseG1GC $JAVA_APP  2>>$OUT_FILE
mv $RESPONSE_TIMES_FILE $STATS_DIR/G1.csv

echo -n vm=HotSpot,gc=Z, >> $OUT_FILE
/usr/bin/time $JAVA_CMD -XX:+UnlockExperimentalVMOptions -XX:+UseZGC $JAVA_APP 2>>$OUT_FILE
mv $RESPONSE_TIMES_FILE $STATS_DIR/Z.csv

echo -n vm=HotSpot,gc=Shenandoah, >> $OUT_FILE
/usr/bin/time $JAVA_CMD -XX:+UnlockExperimentalVMOptions -XX:+UseShenandoahGC $JAVA_APP 2>>$OUT_FILE
mv $RESPONSE_TIMES_FILE $STATS_DIR/Shenandoah.csv

# OpenJ9

echo -n vm=OpenJ9,gc=gencon, >> $OUT_FILE
/usr/bin/time $JAVA_J9_CMD $JAVA_APP 2>>$OUT_FILE
mv $RESPONSE_TIMES_FILE $STATS_DIR/gencon.csv

echo -n vm=OpenJ9,gc=balanced, >> $OUT_FILE
/usr/bin/time $JAVA_J9_CMD -Xgcpolicy:balanced $JAVA_APP 2>>$OUT_FILE
mv $RESPONSE_TIMES_FILE $STATS_DIR/balanced.csv

echo -n vm=OpenJ9,gc=optavgpause, >> $OUT_FILE
/usr/bin/time $JAVA_J9_CMD -Xgcpolicy:optavgpause $JAVA_APP 2>>$OUT_FILE
mv $RESPONSE_TIMES_FILE $STATS_DIR/optavgpause.csv

echo -n vm=OpenJ9,gc=optthruput, >> $OUT_FILE
/usr/bin/time $JAVA_J9_CMD -Xgcpolicy:optthruput $JAVA_APP 2>>$OUT_FILE
mv $RESPONSE_TIMES_FILE $STATS_DIR/optthruput.csv

echo -n vm=OpenJ9,gc=metronome, >> $OUT_FILE
/usr/bin/time $JAVA_J9_CMD -Xgcpolicy:metronome $JAVA_APP 2>>$OUT_FILE
mv $RESPONSE_TIMES_FILE $STATS_DIR/metronome.csv

# Zing

echo -n vm=Zing,gc=C4, >> $OUT_FILE
/usr/bin/time $JAVA_ZING_CMD $JAVA_APP 2>>$OUT_FILE
mv $RESPONSE_TIMES_FILE $STATS_DIR/C4.csv

# SVM

echo -n vm=Substrate,gc=SVM, >> $OUT_FILE
/usr/bin/time ./request-processor $RESPONSE_SIZE $RESPONSE_COUNT $THREAD_COUNT 2>>$OUT_FILE
mv $RESPONSE_TIMES_FILE $STATS_DIR/SVM.csv
