#!/bin/bash

# This script executes an class file with the embeded agent.
#
# You may set the following environments variables to modify the profiler's
# behaviour:
#
#   JINN_PHASE_INTERVAL: The minimum amount of time (in milliseconds)
#                        betwen phases.
#
#   JINN_PHASE_FIXED: When set to `true`, the profiler runs at fixed periods
#                     of time instead of at JVMTI events. This produces a lot
#                     more data samples.
#
#   JINN_SCHED_POLICY: The policy for scheduling the JVM application.
#                      Possible values: SimpleVM
#
# Example:
# ./run.sh -jar SyncTable.jar
# ./run.sh -cp ../sync_soot/inputs/HashSync HashSync 32 1000000 10
# ./run.sh -cp ../sync_soot/inputs/SyncTable SyncTable
# ./run.sh -cp ../sync_soot/inputs/FreqCounter FreqCounter
# ./run.sh -cp ../sync_soot/inputs/JavaFreqCounter FreqCounter 32 1000 4000 30 800 20
# ./run.sh -cp ../sync_soot/inputs/SortedList Sort 32 15000
#

if [ $# -lt 1 ]
then
  echo "./run.sh usual-java-options"
else
  ROOT=`dirname $0`
  AGENTPATH="$ROOT/bin/sync_jvmti.so"

  if [ -z ${JAVA_HOME+x} ]; then
    JAVA=java
  else
    JAVA="$JAVA_HOME/bin/java"
  fi

  $JAVA -agentpath:$AGENTPATH $@
fi
