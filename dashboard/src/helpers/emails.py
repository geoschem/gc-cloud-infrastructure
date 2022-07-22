import boto3

def send_welcome_email(email_address):
    ses_client = boto3.client("ses")
    CHARSET = "UTF-8"
    EMAIL_CONTENT = """
Hello,

Welcome to the GEOS-Chem community!

We invite you to read our GEOS-Chem welcome page and our welcome letter for new GEOS-Chem users:

     http://www.geos-chem.org/geos-welcome 

     http://wiki.geos-chem.org/GEOS-Chem_welcome_letter_for_new_users 

For detailed instructions about how to download, install, and run GEOS-Chem at your institution, please see our comprehensive GEOS-Chem Online User's Guide:
 
     http://manual.geos-chem.org/

    NOTE: We are currently porting the GEOS-Chem manual to https://geos-chem.readthedocs.io.

We also encourage you to create an account on the GEOS-Chem wiki. Navigate to: 

     http://wiki.geos-chem.org/

and then click on the "log in/create account" link at the top right of the page. You can read any wiki page without registering, but you will not be able to contribute content to the wiki if you have not registered.

Please let us know if we can be of further assistance to you. Happy modeling!


Thanks!

The GEOS-Chem Support Team
geos-chem-support@g.harvard.edu


--
Bob Yantosca
Senior Software Engineer
GEOS-Chem Support Team
(based at the Harvard John A. Paulson School of Engineering & Applied Sciences)
yantosca@seas.harvard.edu
(617) 496-9424
 

For assistance with GEOS-Chem, please see:
http://wiki.geos-chem.org/Submitting_GEOS-Chem_support_requests
    """

    response = ses_client.send_email(
        Destination={
            "ToAddresses": [
                email_address,
            ],
        },
        Message={
            "Body": {
                "Text": {
                    "Charset": CHARSET,
                    "Data": EMAIL_CONTENT,
                }
            },
            "Subject": {
                "Charset": CHARSET,
                "Data": "Welcome to GEOS-Chem",
            },
        },
        Source="geos-chem-support@g.harvard.edu",
    )
    return response