# The cluster you created using terraform-ecs
cluster = "datacube-dev"

# The name of your project
workspace = "s2-nrt-au-archive"

# Setting this to false will turn off auto-restart and web access
webservice = false

# The number of containers to run at once
task_desired_count = 1

# The name of the database
database = "datacube-dev.nrtau"

# The name of the service
name = "datacube-wms-s2-au-archive"

# The docker image to deploy
docker_image = "geoscienceaustralia/datacube-wms:aux_archive"

# environment variables configuring the docker container
environment_vars = {
  "DC_S3_ARCHIVE_BUCKET" = "dea-public-data"
  "DC_S3_ARCHIVE_PREFIX" = "L2/sentinel-2-nrt/S2MSIARD/"
  "DC_S3_ARCHIVE_SUFFIX" = "ARD-METADATA.yaml"
  "DC_ARCHIVE_DAYS"      = 31
}

schedulable = true

schedule_expression = "cron(1 13 * * ? *)"

custom_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "GetFiles",
            "Effect": "Allow",
            "Action": [
                "s3:*"
            ],
            "Resource": [
                "arn:aws:s3:::dea-public-data",
                "arn:aws:s3:::dea-public-data/*"
            ]
        }
    ]
}
EOF
