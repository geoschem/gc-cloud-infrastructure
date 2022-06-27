import json

from .models.user_entry import UserEntry
from .helpers.utilities import fill_template, apply_filters, parse_user_registration, render_page
from .models.registry_entry_simulation import RegistryEntrySimulation
from .models.registry_entry_diff import RegistryEntryDiff
from .helpers.dynamodb import *


def dashboard(event, context):
    expression = "InstanceID,CreationDate,ExecStatus,Site,Description"
    entries = apply_filters(event, scan_registry("geoschem_testing", expression))
    if event["path"] == "/filter":
        entries = [
            entry
            for entry in entries
            if entry.primary_key_classification.time_period
            == event["queryStringParameters"]["time_period"]
        ]
    entries.sort(key=lambda entry: entry.creation_date, reverse=True)
    html_page = fill_template("testing-dashboard.html", entries=entries)
    return render_page(html_page)


def simulation(event, context):
    primary_key = event["queryStringParameters"]["primary_key"]
    entries = query_registry(primary_key, RegistryEntrySimulation, "geoschem_testing")
    html_page = fill_template("simulation.html", entry=entries[0])
    return render_page(html_page)


def difference(event, context):
    primary_key = event["queryStringParameters"]["primary_key"]
    entries = query_registry(primary_key, RegistryEntryDiff, "geoschem_testing")
    html_page = fill_template("difference.html", entry=entries[0])
    return render_page(html_page)


def registration(event, context):
    item = parse_user_registration(json.loads(event["body"]))
    put_item("geoschem_users", item)
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "text/html",
        },
        "body": "Successful Registration"
    }


def users(event, context):
    expression = "EmailAddress,Affiliation,Site,GitUsername,ResearchInterest,EpochTimeCreateDate"
    entries = scan_registry("geoschem_users", expression, astype=UserEntry)
    entries.sort(key=lambda entry: entry.creation_date, reverse=True)
    html_page = fill_template("user-dashboard.html", entries=entries)
    return render_page(html_page)


def test(event, context):
    return {"event": event}

def handler(event, context):

    if event["path"] == "/difference":
        output = difference(event, context)
    elif event["path"] == "/simulation":
        output = simulation(event, context)
    elif event["path"] == "/test":
        output = test(event, context)
    elif event["path"] == "/registration":
        output = registration(event, context)
    elif event["path"] == "/users":
        output = users(event, context)
    else:
        output = dashboard(event, context)
    return output
