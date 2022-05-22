import dataclasses
import typing
from ..helpers.model_helpers import dynamodb_decode_dict


@dataclasses.dataclass
class RegistryEntryStage:
    name: str = None
    completed: bool = None
    log_file: str = None
    start_time: str = None
    end_time: str = None
    artifacts: typing.List[str] = dataclasses.field(default_factory=list)
    public_artifacts: typing.List[str] = dataclasses.field(default_factory=list)
    metadata: str = "{}"
    dynamodb_stage_result: dataclasses.InitVar[dict] = None

    def __post_init__(self, dynamodb_stage_result):
        if dynamodb_stage_result is not None:
            dynamodb_stage_result = dynamodb_decode_dict(dynamodb_stage_result)
            self.name = dynamodb_stage_result.get("Name")
            self.log_file = dynamodb_stage_result.get("Log")
            self.completed = dynamodb_stage_result.get("Completed")
            self.start_time = dynamodb_stage_result.get("StartTime")
            self.end_time = dynamodb_stage_result.get("EndTime")
            self.artifacts = dynamodb_stage_result.get("Artifacts")
            self.public_artifacts = dynamodb_stage_result.get("PublicArtifacts")
            self.metadata = dynamodb_stage_result.get("Metadata")
