#!/bin/bash
#SBATCH -p debug
#SBATCH -N 6
#SBATCH -t 00:30:00
#SBATCH -J sparkFITS
#SBATCH -C haswell
#SBATCH --image=nersc/spark-2.3.0:v1
#SBATCH -A m1727

module load spark
module load sbt

## SBT Version
SBT_VERSION=2.11.8
SBT_VERSION_SPARK=2.11

## Package version
VERSION=0.1.0

# Package it
sbt ++${SBT_VERSION} package

# External JARS
SF=lib/spark-fits_2.11-0.2.0.jar
HP=lib/jhealpix.jar

# Parameters
nside=512
loop=10

# Run it!
start-all.sh

# 110G, 550, 1100 GB
for replication in 0 4 9; do
  fitsfn="/global/cscratch1/sd/peloton/LSST10Y_striped_high"
  shifter spark-submit \
    --master $SPARKURL \
    --driver-memory 15g --executor-memory 50g --executor-cores 32 --total-executor-cores 192 \
    --jars ${SF},${HP} \
    --class com.apps.healpix.HealpixProjection \
    target/scala-${SBT_VERSION_SPARK}/healpixprojection_${SBT_VERSION_SPARK}-${VERSION}.jar \
    $fitsfn $nside $replication $loop
  wait
done

stop-all.sh
