import json
import logging
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

codepipeline = boto3.client('codepipeline')

def lambda_handler(event, context):
    logger.info("Received event: %s", json.dumps(event))

    detail = event.get('detail', {})
    pipeline = detail.get('pipeline', 'unknown')
    execution_id = detail.get('execution-id', 'unknown')
    state = detail.get('state', 'unknown')

    logger.error(f"[ALERT] CodePipeline '{pipeline}' FAILED. Execution ID: {execution_id} | State: {state}")

    try:
        # Fetch pipeline execution summary
        response = codepipeline.get_pipeline_execution(
            pipelineName=pipeline,
            pipelineExecutionId=execution_id
        )

        execution = response.get("pipelineExecution", {})
        execution_status = execution.get("status", "unknown")
        failure_reason = execution.get("failureReason", "No top-level failure reason provided.")

        logger.error(f"[SUMMARY] Execution Status: {execution_status}")
        logger.error(f"[TOP-LEVEL REASON] {failure_reason}")

        # Now get details of all stage executions
        stage_response = codepipeline.list_action_executions(
            pipelineName=pipeline,
            filter={
                'pipelineExecutionId': execution_id
            }
        )

        for action in stage_response.get('actionExecutionDetails', []):
            if action.get('status') == 'Failed':
                stage_name = action.get('stageName')
                action_name = action.get('actionName')
                error_message = action.get('errorDetails', {}).get('message', 'No error message provided.')
                external_exec_url = action.get('externalExecutionUrl', 'No external URL')

                logger.error(f"[FAILURE] Stage: {stage_name} | Action: {action_name}")
                logger.error(f"[ERROR MESSAGE] {error_message}")
                logger.error(f"[EXECUTION URL] {external_exec_url}")

    except Exception as e:
        logger.exception("Failed to fetch or process pipeline execution details.")

    return {
        'statusCode': 200,
        'body': json.dumps('Detailed failure notification processed.')
    }
