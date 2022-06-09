import jinja2


def fill_template(template_file, **kwargs):
    templateLoader = jinja2.FileSystemLoader(searchpath="./src/templates/")
    templateEnv = jinja2.Environment(loader=templateLoader)
    template = templateEnv.get_template(template_file)
    html_page = template.render(**kwargs)
    html_page = html_page.replace(
        "SUCCESSFUL", '<span style="color:green">✅ SUCCESSFUL</span>'
    )
    html_page = html_page.replace(
        "IN_PROGRESS", '<span style="color:orange">⌛ IN_PROGRESS</span>'
    )
    html_page = html_page.replace("FAILED", '<span style="color:red">❌ FAILED</span>')
    return html_page

def create_public_artifacts(public_artifacts):
    updated_artifacts = []
    for artifact in public_artifacts:
        name = artifact.split("BenchmarkResults/",1)[1]
        updated_artifacts.append({"url": artifact, "name": name})
    return updated_artifacts

# filter entries based on querystring parameters
def apply_filters(event, entries):
    if event["rawPath"] == "/search":
        search_string = event["queryStringParameters"]["searchString"]
        hour_filter = event["queryStringParameters"]["1Hr"] if "1Hr" in event["queryStringParameters"] else None
        monthly_filter = event["queryStringParameters"]["1Mon"] if "1Mon" in event["queryStringParameters"] else None

        if not hour_filter and monthly_filter:
            time_period = hour_filter or monthly_filter or None
            entries = [
                entry
                for entry in entries
                if entry.primary_key_classification.time_period == time_period
            ]
        if search_string != "":
            entries = [entry for entry in entries if search_string in entry.primary_key]

    return entries

