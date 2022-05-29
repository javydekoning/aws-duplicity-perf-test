#!/bin/bash

SRC=/backupsrc/
DST=/backupdst/
CFG=/duplicati/
DATASET=s3://javydekoning/backuptesting/dataset.zip #dataset.zip
DEMOSET=s3://javydekoning/backuptesting/demo.zip

mkdir $SRC
mkdir $DST
mkdir $CFG

echo "=============================================================================="
uname -r
echo "=============================================================================="
echo "Preparing instance...."
start=`date +%s`
yum install -y docker unzip duplicity -q
systemctl enable docker.service
systemctl start docker.service -q
docker pull ghcr.io/tecnativa/docker-duplicity-s3:latest -q
end=`date +%s`
runtime=$((end-start))
echo "install took $runtime seconds"

echo "=============================================================================="
echo "Starting s3 download...."
start=`date +%s`
aws s3 cp $DATASET ./archive.zip --quiet
end=`date +%s`
runtime=$((end-start))
echo "s3 download took $runtime seconds"

echo "=============================================================================="
echo "Unzipping example dataset...."
start=`date +%s`
unzip -q archive.zip -d $SRC
end=`date +%s`
runtime=$((end-start))
echo "unzip took $runtime seconds"

echo "=============================================================================="
echo "Starting backup of $(find $SRC -type f | wc -l) files ($(du -sh $SRC | cut -f 1))"

echo "=============================================================================="
echo "DOCKER: Starting backup...."
start=`date +%s`

docker run \
--rm \
--name duplicity \
--volume duplicity-cache:/root \
--volume $SRC:/backup/:ro \
--volume $DST:/destination/ \
ghcr.io/tecnativa/docker-duplicity-s3:latest duplicity full --progress \
--progress-rate 60 --no-encryption --volsize 100 /backup file:///destination/

end=`date +%s`
runtime=$((end-start))
echo "Backup via duplicity (CONTAINER) took $runtime seconds"

echo "=============================================================================="
echo "NATIVE: Starting backup...."
start=`date +%s`
rm -rf $DST
mkdir $DST
duplicity full --progress --progress-rate 60 --no-encryption --volsize 100 $SRC file://$DST
end=`date +%s`
runtime=$((end-start))
echo "Backup via duplicity (NATIVE) took $runtime seconds"

echo "=============================================================================="
echo "DOCKER: Starting restore...."
start=`date +%s`
rm -rf $SRC
mkdir $SRC

docker run \
--rm \
--name duplicity \
--volume duplicity-cache:/root \
--volume $SRC:/backup/ \
--volume $DST:/destination/ \
ghcr.io/tecnativa/docker-duplicity-s3:latest \
duplicity restore --progress --progress-rate 60 --no-encryption file:///destination/ /backup 
end=`date +%s`
runtime=$((end-start))
echo "Restore via duplicity (CONTAINER) took $runtime seconds"
echo "Restored $(find $SRC -type f | wc -l) files $(du -sh $SRC | cut -f 1)"

echo "=============================================================================="
echo "NATIVE: Starting restore...."

start=`date +%s`
rm -rf $SRC
mkdir $SRC
duplicity restore --progress --progress-rate 60 --no-encryption file://$DST $SRC 
end=`date +%s`
runtime=$((end-start))
echo "Restore via duplicity (NATIVE) took $runtime seconds"
echo "Restored $(find $SRC -type f | wc -l) files $(du -sh $SRC | cut -f 1)"
echo "=============================================================================="