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

