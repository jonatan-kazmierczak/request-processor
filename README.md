# Request Processor
Sample, memory-intensive application in Java for testing of Garbage Collectors. 

### Build a JAR file
If you have Gradle installed, then
```bash
gradle build
```

Otherwise
```bash
./gradlew build
```

### Build an executable
using [GraalVM Native Image](https://www.graalvm.org/docs/reference-manual/native-image/).

Once GraalVM with `native-image` is installed:
```bash
$GRAALVM_HOME/bin/native-image -jar build/libs/request-processor.jar
```

### Adapt and run tests
- Adapt paths to JVMs in `collect_gc_stats.sh`
- Run tests
```bash
./collect_gc_stats.sh
```
