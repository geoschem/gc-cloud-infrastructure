from .helpers.utilities import fill_template, apply_filters
from .models.registry_entry_simulation import RegistryEntrySimulation
from .models.registry_entry_diff import RegistryEntryDiff
from .helpers.dynamodb import *


def dashboard(event, context):
    entries = apply_filters(event, scan_registry())
    if event["rawPath"] == "/filter":
        entries = [
            entry
            for entry in entries
            if entry.primary_key_classification.time_period
            == event["queryStringParameters"]["time_period"]
        ]
    entries.sort(key=lambda entry: entry.creation_date, reverse=True)
    html_page = fill_template("dashboard.html", entries=entries)
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "text/html",
        },
        "body": html_page,
    }


def simulation(event, context):
    primary_key = event["queryStringParameters"]["primary_key"]
    entries = query_registry(primary_key, RegistryEntrySimulation)
    html_page = fill_template("simulation.html", entry=entries[0])
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "text/html",
        },
        "body": html_page,
    }


def difference(event, context):
    primary_key = event["queryStringParameters"]["primary_key"]
    entries = query_registry(primary_key, RegistryEntryDiff)
    html_page = fill_template("difference.html", entry=entries[0])
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "text/html",
        },
        "body": html_page,
    }


def test(event, context):
    return {"event": event}

def registration(event, context):
    print(event)
    print(context)
    return event
    
def handler(event, context):

    if event["rawPath"] == "/difference":
        output = difference(event, context)
    elif event["rawPath"] == "/simulation":
        output = simulation(event, context)
    elif event["rawPath"] == "/test":
        output = test(event, context)
    elif event["rawPath"] == "/registration":
        output = registration(event, context)
    else:
        output = dashboard(event, context)
    return output
