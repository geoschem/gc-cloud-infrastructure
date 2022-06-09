import dataclasses
from .primary_key_classification import PrimaryKeyClassification
from ..helpers.model_helpers import dynamodb_decode_dict


@dataclasses.dataclass
class RegistryEntry:
    primary_key: str = None
    creation_date: str = None
    execution_status: str = None
    execution_site: str = None
    s3_uri: str = None
    description: str = None
    primary_key_classification: PrimaryKeyClassification = None
    dynamodb_scan_result: dataclasses.InitVar[dict] = None

    def __post_init__(self, dynamodb_scan_result):
        if dynamodb_scan_result is not None:
            dynamodb_scan_result = dynamodb_decode_dict(dynamodb_scan_result)
            self.primary_key = dynamodb_scan_result.get("InstanceID")
            self.creation_date = dynamodb_scan_result.get("CreationDate")
            self.execution_status = dynamodb_scan_result.get("ExecStatus")
            self.execution_site = dynamodb_scan_result.get("Site")
            self.s3_uri = dynamodb_scan_result.get("S3Uri")
            self.description = dynamodb_scan_result.get("Description")
        self.primary_key_classification = PrimaryKeyClassification(
            primary_key=self.primary_key
        )
