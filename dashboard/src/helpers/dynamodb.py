import boto3
from ..models.registry_entry import RegistryEntry

# helper methods for interacting with dynamodb


def dynamodb_decode_dict(d: dict):
    new_dict = {}
    for k, v in d.items():
        new_dict[k] = dynamodb_decode_item(v)
    return new_dict


def dynamodb_decode_item(d: dict):
    if not isinstance(d, dict):
        raise TypeError(f"Value of DynamoDB dict is not a nested dict.")
    if len(d) != 1:
        raise ValueError(f"Number of key-value pairs in DynamoDB dict is not one.")
    item = list(d.values())[0]
    if isinstance(item, list):
        item = [dynamodb_decode_item(e) for e in item]
    elif isinstance(item, dict):
        item = {k: dynamodb_decode_item(v) for k, v in item.items()}
    return item


def dynamodb_encode_item(v):
    if isinstance(v, str):
        return {"S": v}
    elif isinstance(v, bool):
        return {"BOOL": v}
    elif isinstance(v, list):
        return {"L": [dynamodb_encode_item(e) for e in v]}
    elif isinstance(v, dict):
        return {"M": {kk: dynamodb_encode_item(vv) for kk, vv in v.items()}}
    else:
        raise TypeError(f"Invalid type for encoding: {type(v).__name__}")


def dynamodb_encode_dict(d: dict):
    new_dict = {}
    for k, v in d.items():
        new_dict[k] = dynamodb_encode_item(v)
    return new_dict


def get_dynamodb_client():
    dynamodb_client = boto3.client("dynamodb")
    return dynamodb_client


def parse_scan_response(response, astype):
    entries = [astype(dynamodb_scan_result=item) for item in response]
    return entries


def scan_registry(table, expression, start_key=None, previous_entries=None, astype=RegistryEntry):
    client = get_dynamodb_client()
    if start_key is None:
        response = client.scan(
            TableName=table,
            ProjectionExpression=expression,
        )
    else:
        response = client.scan(
            TableName=table,
            ProjectionExpression=expression,
            ExclusiveStartKey=start_key,
        )
    entries = parse_scan_response(response["Items"], astype)

    if previous_entries is not None:
        entries = previous_entries + entries

    # handle pagination of dynamodb results
    if "LastEvaluatedKey" in response:
        return scan_registry(
            table, expression, response["LastEvaluatedKey"], previous_entries=entries
        )
    else:
        return entries


def parse_query_response_astype(query_results, astype):
    entries = []
    for item in query_results:
        entries.append(astype(dynamodb_query_result=item))
    return entries


def query_registry(items, astype, table):
    client = get_dynamodb_client()

    if isinstance(items, str):
        request_keys = [{"InstanceID": {"S": items}}]
    else:
        request_keys = [{"InstanceID": {"S": item.primary_key}} for item in items]
    response = client.batch_get_item(RequestItems={table: {"Keys": request_keys}})

    if astype is dict:
        return [
            dynamodb_decode_dict(response) for response in response["Responses"][table]
        ]
    else:
        return parse_query_response_astype(response["Responses"][table], astype)


def put_item(table, item):
    client = get_dynamodb_client()
    client.put_item(TableName=table, Item=item)
