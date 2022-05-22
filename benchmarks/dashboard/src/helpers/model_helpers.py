# TODO figure out how to avoid repeating this code
# Note: importing from dynamod causes circular dependency
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