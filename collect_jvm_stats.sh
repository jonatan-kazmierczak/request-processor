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
# Path to java command from OpenJDK build
JAVA_CMD=/opt2/jdk-15.0.1+9_hotspot/bin/java
# Path to java command from OpenJDK with OpenJ9 VM
JAVA_J9_CMD=/opt2/jdk-15.0.1+9_openj9/bin/java
# Path to java command from Zing VM
JAVA_ZING_CMD=/opt2/zing20.12.0.0-5-ca-jdk11.0.9-linux_x64/bin/java
# Path to java command from GraalVM
JAVA_GRAALVM_CMD=/opt2/graalvm-ce-java11-20.3.0/bin/java

echo "-- Java GC Performance Statistics Collector --"
echo "Please make sure, that you are not running it in virtualized environment (i.e. Docker) and that your CPU runs on a constant frequency"
echo

$JAVA_CMD -version
echo

OUT_FILE=$STATS_DIR/gc.txt

mkdir -p $STATS_DIR

# HotSpot
echo -n vm=HotSpot,gc=G1, > $OUT_FILE
/usr/bin/time $JAVA_CMD $JAVA_APP 2>>$OUT_FILE
mv $RESPONSE_TIMES_FILE $STATS_DIR/G1.csv

# OpenJ9
echo -n vm=OpenJ9,gc=gencon, >> $OUT_FILE
/usr/bin/time $JAVA_J9_CMD $JAVA_APP 2>>$OUT_FILE
mv $RESPONSE_TIMES_FILE $STATS_DIR/gencon.csv

# Zing
echo -n vm=Zing,gc=C4, >> $OUT_FILE
/usr/bin/time $JAVA_ZING_CMD $JAVA_APP 2>>$OUT_FILE
mv $RESPONSE_TIMES_FILE $STATS_DIR/C4.csv

# HotSpot (GraalVM)
echo -n vm=GraalVM,gc=G1, >> $OUT_FILE
/usr/bin/time $JAVA_GRAALVM_CMD $JAVA_APP 2>>$OUT_FILE
mv $RESPONSE_TIMES_FILE $STATS_DIR/GraalVM-G1.csv

# Substrate
echo -n vm=Substrate,gc=none, >> $OUT_FILE
/usr/bin/time ./request-processor $RESPONSE_SIZE $RESPONSE_COUNT $THREAD_COUNT 2>>$OUT_FILE
mv $RESPONSE_TIMES_FILE $STATS_DIR/SVM.csv
