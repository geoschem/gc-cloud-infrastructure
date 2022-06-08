import re

def find_matching_keys(mydict, mykey):
    result = []
    num_recursive_calls = 0

    def explore(mydict, mykey):
        #nonlocal result      #allow successive recursive calls to write to list
                              #actually this is unnecessary in this case! Here 
                              #is where we would need it, for a call counter: 
        nonlocal num_recursive_calls
        num_recursive_calls += 1
        for key in mydict.keys():   #get all keys from that level of nesting
            if mykey == key:
                print(f"Found {key}")
                result.append(mydict[key])

            elif isinstance(mydict.get(key), dict):
                print(f"Found nested dict under {key}, exploring")
                explore(mydict[key], mykey)

    explore(mydict, mykey)
    return result


def parse_error(event):
    key = "Cause"
    statuses = find_matching_keys(event, key)
    matches = [status for status in statuses if re.search("Host EC2 .* terminated.", status) ]
    if len(matches) > 0:
        return {"errorStatus": "Interruption"}
    else:
        return {"errorStatus": "Error"}
        
def handler(event, context):
    return parse_error(event)
