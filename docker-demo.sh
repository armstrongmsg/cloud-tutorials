# Download spark image
docker pull cloudsuite/spark

# Network configuration
docker network create --driver bridge spark-net

# Start master
docker run -it --cpus="1" -dP --net spark-net --hostname spark-master --name spark-master cloudsuite/spark master
# List containers 
docker ps

# Get master IP
MASTER_IP=$(docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' spark-master)

# Start worker 1
docker run -it --cpus="1" -dP --net spark-net --name spark-worker-01 cloudsuite/spark worker spark://spark-master:7077
# List containers
docker ps

# Start shell session
docker run -it --rm --net spark-net cloudsuite/spark bash
# Run application
/opt/spark-2.1.0/bin/spark-submit --class org.apache.spark.examples.SparkPi --master spark://spark-master:7077 /opt/spark-2.1.0/examples/jars/spark-examples_2.11-2.1.0.jar 1000

# Start worker 2
docker run -it --cpus="1" -dP --net spark-net --name spark-worker-02 cloudsuite/spark worker spark://spark-master:7077
# List containers
docker ps

# Start shell session
docker run -it --rm --net spark-net cloudsuite/spark bash
# Run application
/opt/spark-2.1.0/bin/spark-submit --class org.apache.spark.examples.SparkPi --master spark://spark-master:7077 /opt/spark-2.1.0/examples/jars/spark-examples_2.11-2.1.0.jar 1000

# Start worker 3
docker run -it --cpus="1" -dP --net spark-net --name spark-worker-03 cloudsuite/spark worker spark://spark-master:7077
# List containers
docker ps

# Start shell session
docker run -it --rm --net spark-net cloudsuite/spark bash
# Run application
/opt/spark-2.1.0/bin/spark-submit --class org.apache.spark.examples.SparkPi --master spark://spark-master:7077 /opt/spark-2.1.0/examples/jars/spark-examples_2.11-2.1.0.jar 1000

