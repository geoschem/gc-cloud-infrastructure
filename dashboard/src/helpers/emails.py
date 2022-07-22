import boto3

def send_email(source, destination, subject, html_message):
    ses_client = boto3.client("ses")
    CHARSET = "UTF-8"
    try:
        response = ses_client.send_email(
            Destination={
                "ToAddresses": [
                    destination,
                ],
            },
            Message={
                "Body": {
                    "Html": {
                        "Charset": CHARSET,
                        "Data": html_message,
                    }
                },
                "Subject": {
                    "Charset": CHARSET,
                    "Data": subject,
                },
            },
            Source=source,
        )
        return response
    except Exception as e:
        print(e)
        return e

def send_welcome_email(destination):
    source = "geos-chem-support@g.harvard.edu"
    subject = "Welcome to GEOS-Chem!"
    html_message = """
<html>
<head></head>
<body>
    <h1></h1>
    <p class="MsoNormal"><span style="font-size:12.0pt;font-family:&quot;Georgia&quot;,serif">Dear New User of
            GEOS-Chem:<o:p></o:p></span></p>
    <p class="MsoNormal"><span style="font-size:12.0pt;font-family:&quot;Georgia&quot;,serif">
            <o:p>&nbsp;</o:p>
        </span></p>
    <p class="MsoNormal"><span style="font-size:12.0pt;font-family:&quot;Georgia&quot;,serif">Welcome to the GEOS-Chem
            community! We hope that you find GEOS-Chem a useful tool for your work and we look forward to working with
            you. GEOS-Chem is a grass-roots model that relies on contributions and good practice from its users. We ask
            that you browse through the GEOS-Chem web pages to familiarize yourself with the model and its user
            community. We also ask that you consider the following &quot;good practice&quot; protocol:<o:p></o:p></span>
    </p>
    <p class="MsoNormal"><span style="font-size:12.0pt;font-family:&quot;Georgia&quot;,serif">
            <o:p>&nbsp;</o:p>
        </span></p>
    <ul style="margin-top:0in" type="disc">
        <li class="MsoListParagraph" style="margin-left:0in;mso-list:l0 level1 lfo1"><span
                style="font-size:12.0pt;font-family:&quot;Georgia&quot;,serif"><a
                    href="https://geos-chem.seas.harvard.edu/geos-working-groups">Subscribe to GEOS-Chem working
                    groups</a> and stay informed through the model newsletters and wiki pages <o:p></o:p></span></li>
        <li class="MsoListParagraph" style="margin-left:0in;mso-list:l0 level1 lfo1">
            <span style="font-size:12.0pt;font-family:&quot;Georgia&quot;,serif"><a
                    href="https://geos-chem.seas.harvard.edu/geos-new-developments">Offer credit to recent
                    developers</a> in publications, and provide proper <a
                    href="https://geos-chem.seas.harvard.edu/geos-chem-narrative">
                    citation to older model developments</a>
                <o:p></o:p>
            </span>
        </li>
        <li class="MsoListParagraph" style="margin-left:0in;mso-list:l0 level1 lfo1"><span
                style="font-size:12.0pt;font-family:&quot;Georgia&quot;,serif">Contribute bug reports and fixes to the
                GEOS-Chem support team via
                <a href="https://github.com/geoschem/geos-chem/issues/new/choose">Github issues</a>
                <o:p></o:p>
            </span></li>
        <li class="MsoListParagraph" style="margin-left:0in;mso-list:l0 level1 lfo1"><span
                style="font-size:12.0pt;font-family:&quot;Georgia&quot;,serif">Upgrade regularly to the latest
                <a href="http://wiki.seas.harvard.edu/geos-chem/index.php/GEOS-Chem_versions">standard version of the
                    model</a>
                <o:p></o:p>
            </span></li>
        <li class="MsoListParagraph" style="margin-left:0in;mso-list:l0 level1 lfo1"><span
                style="font-size:12.0pt;font-family:&quot;Georgia&quot;,serif">Help out as you can in response to user
                requests<o:p></o:p></span></li>
        <li class="MsoListParagraph" style="margin-left:0in;mso-list:l0 level1 lfo1"><span
                style="font-size:12.0pt;font-family:&quot;Georgia&quot;,serif">Contribute mature new developments to the
                standard model
                <o:p></o:p>
            </span></li>
    </ul>
    <p class="MsoNormal"><span style="font-size:12.0pt;font-family:&quot;Georgia&quot;,serif">
            <o:p>&nbsp;</o:p>
        </span></p>
    <p class="MsoNormal"><span style="font-size:12.0pt;font-family:&quot;Georgia&quot;,serif">Please also
            <a
                href="https://geos-chem.readthedocs.io/en/latest/geos-chem-shared-docs/supplemental-guides/related-docs.html">
                follow this link</a> to view online documentation for GEOS-Chem and relatedsoftware.&nbsp; We also
            invite you to view our video tutorials at
            <a href="https://youtube.com/c/geoschem">youtube.com/c/geoschem</a>.<o:p></o:p></span></p>
    <p class="MsoNormal"><span style="font-size:12.0pt;font-family:&quot;Georgia&quot;,serif">
            <o:p>&nbsp;</o:p>
        </span></p>
    <p class="MsoNormal"><span style="font-size:12.0pt;font-family:&quot;Georgia&quot;,serif">Many new GEOS-Chem users
            start with
            <a href="https://geos-chem.readthedocs.io/">GEOS-Chem Classic</a>, which is the
            single-node mode of running GEOS-Chem. But if your research requires you to run simulations on extremely
            fine horizontal grids, or if you would like to use more than a single computational node, you will
            want to use <a href="https://gchp.readthedocs.io/">
                GEOS-Chem High Performance (GCHP)</a>, which is our multi-node mode of running GEOS-Chem.
            <o:p></o:p>
        </span></p>
    <p class="MsoNormal"><span style="font-size:12.0pt;font-family:&quot;Georgia&quot;,serif">
            <o:p>&nbsp;</o:p>
        </span></p>
    <p class="MsoNormal"><span style="font-size:12.0pt;font-family:&quot;Georgia&quot;,serif">Sincerely,<o:p></o:p>
            </span></p>
    <p class="MsoNormal"><span style="font-size:12.0pt;font-family:&quot;Georgia&quot;,serif">
            <o:p>&nbsp;</o:p>
        </span></p>
    <p class="MsoNormal"><span style="font-size:12.0pt;font-family:&quot;Georgia&quot;,serif">The GEOS-Chem Steering
            Committee and<br>
            The GEOS-Chem Support Team<o:p></o:p></span></p>
    <p class="MsoNormal"><span style="font-size:12.0pt;font-family:&quot;Georgia&quot;,serif">
            <o:p>&nbsp;</o:p>
        </span></p>
    <p class="MsoNormal"><span style="font-size:12.0pt;font-family:&quot;Georgia&quot;,serif">
            <o:p>&nbsp;</o:p>
        </span></p>
</body>
</html>
    """
    return send_email(source, destination, subject, html_message)
    

