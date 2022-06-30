import datetime
import dataclasses
from ..helpers.model_helpers import dynamodb_decode_dict


@dataclasses.dataclass
class UserEntry:
    primary_key: str = None
    creation_date: str = None
    affiliation: str = None
    site: str = None
    git_username: str = None
    model_type: str = None
    research_interest: str = None
    env_type: str = None
    dynamodb_scan_result: dataclasses.InitVar[dict] = None

    def __post_init__(self, dynamodb_scan_result):
        if dynamodb_scan_result is not None:
            dynamodb_scan_result = dynamodb_decode_dict(dynamodb_scan_result)
            self.primary_key = dynamodb_scan_result.get("EmailAddress")
            self.creation_date = datetime.datetime.fromtimestamp(
                float(dynamodb_scan_result.get("EpochTimeCreateDate"))
            ).strftime("%m-%d-%Y")
            self.affiliation = dynamodb_scan_result.get("Affiliation")
            self.site = dynamodb_scan_result.get("Site")
            self.git_username = dynamodb_scan_result.get("GitUsername")
            self.model_type = dynamodb_scan_result.get("ModelType")
            self.env_type = dynamodb_scan_result.get("EnvType")
            self.research_interest = dynamodb_scan_result.get("ResearchInterest")
