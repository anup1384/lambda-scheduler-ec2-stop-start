# -*- coding: utf-8 -*-

"""This script stop and start aws resources."""
import os

from scheduler.instance_handler import InstanceScheduler


def lambda_handler(event, context):
    """Main function entrypoint for lambda.

    Stop and start AWS resources:
    - instance ec2

    """
    _strategy = {}
    # Retrieve variables from aws lambda ENVIRONMENT
    schedule_action = os.getenv("SCHEDULE_ACTION")
    aws_regions = os.getenv("AWS_REGIONS").replace(" ", "").split(",")
    tag_key = os.getenv("TAG_KEY")
    tag_value = os.getenv("TAG_VALUE")
    _strategy[InstanceScheduler] = os.getenv("EC2_SCHEDULE")

    for key, value in _strategy.items():
        for aws_region in aws_regions:
            strategy = key(aws_region)
            if schedule_action == "stop" and value == "true":
                strategy.stop(tag_key, tag_value)
            elif schedule_action == "start" and value == "true":
                strategy.start(tag_key, tag_value)
