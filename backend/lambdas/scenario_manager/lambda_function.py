import json
import os
import uuid
from datetime import datetime, timezone
from decimal import Decimal

import boto3
from boto3.dynamodb.conditions import Key
from botocore.exceptions import ClientError

s3  = boto3.client('s3')
ddb = boto3.resource('dynamodb')

BUCKET = os.environ['S3_BUCKET']   # steam-cracker-reports
TABLE  = os.environ['DDB_TABLE']   # SteamCrackerScenarios

table = ddb.Table(TABLE)

HEADERS = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
}


def _to_decimal(obj):
    if isinstance(obj, float):
        return Decimal(str(obj))
    if isinstance(obj, dict):
        return {k: _to_decimal(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [_to_decimal(i) for i in obj]
    return obj


def _from_decimal(obj):
    if isinstance(obj, Decimal):
        return float(obj)
    if isinstance(obj, dict):
        return {k: _from_decimal(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [_from_decimal(i) for i in obj]
    return obj


def respond(status: int, body: dict):
    return {'statusCode': status, 'headers': HEADERS, 'body': json.dumps(_from_decimal(body))}


def handler(event, _context):
    try:
        body   = json.loads(event.get('body') or '{}')
        action = body.get('action')

        if action == 'save':
            return _save(body)
        if action == 'list':
            return _list(body)
        if action == 'get':
            return _get(body)
        if action == 'delete':
            return _delete(body)

        return respond(400, {'error': f'Unknown action: {action}'})
    except Exception as exc:
        return respond(500, {'error': str(exc)})


# ── Save ─────────────────────────────────────────────────────────────────────

def _save(body: dict):
    user_id  = body.get('userId')
    metadata = body.get('metadata', {})
    results  = body.get('results', {})

    if not user_id:
        return respond(400, {'error': 'userId required'})

    scenario_id = str(uuid.uuid4())
    s3_key      = f'scenarios/{user_id}/{scenario_id}.json'

    s3.put_object(
        Bucket=BUCKET,
        Key=s3_key,
        Body=json.dumps(results),
        ContentType='application/json',
    )

    table.put_item(Item=_to_decimal({
        'userId':     user_id,
        'scenarioId': scenario_id,
        's3Key':      s3_key,
        'createdAt':  datetime.now(timezone.utc).isoformat(),
        **metadata,
    }))

    return respond(200, {'scenarioId': scenario_id, 's3Key': s3_key})


# ── List ──────────────────────────────────────────────────────────────────────

def _list(body: dict):
    user_id = body.get('userId')
    if not user_id:
        return respond(400, {'error': 'userId required'})

    resp  = table.query(KeyConditionExpression=Key('userId').eq(user_id))
    items = resp.get('Items', [])
    items.sort(key=lambda x: x.get('createdAt', ''), reverse=True)

    return respond(200, {'scenarios': items})


# ── Get full results from S3 ──────────────────────────────────────────────────

def _get(body: dict):
    s3_key = body.get('s3Key')
    if not s3_key:
        return respond(400, {'error': 's3Key required'})

    try:
        obj     = s3.get_object(Bucket=BUCKET, Key=s3_key)
        results = json.loads(obj['Body'].read())
        return respond(200, {'results': results})
    except ClientError:
        return respond(404, {'error': 'Scenario results not found'})


# ── Delete ────────────────────────────────────────────────────────────────────

def _delete(body: dict):
    user_id     = body.get('userId')
    scenario_id = body.get('scenarioId')
    s3_key      = body.get('s3Key')

    if not user_id or not scenario_id:
        return respond(400, {'error': 'userId and scenarioId required'})

    table.delete_item(Key={'userId': user_id, 'scenarioId': scenario_id})

    if s3_key:
        try:
            s3.delete_object(Bucket=BUCKET, Key=s3_key)
        except ClientError:
            pass  # best effort

    return respond(200, {'deleted': scenario_id})
