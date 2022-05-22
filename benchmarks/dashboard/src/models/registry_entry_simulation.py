import dataclasses
from .registry_entry_stage import RegistryEntryStage
from .registry_entry import RegistryEntry


@dataclasses.dataclass
class RegistryEntrySimulation(RegistryEntry):
    setup_run_directory: RegistryEntryStage = None
    run_simulation_directory: RegistryEntryStage = None
    dynamodb_query_result: dataclasses.InitVar[dict] = None

    def __post_init__(self, dynamodb_scan_result, dynamodb_query_result):
        if dynamodb_query_result is not None:
            super().__post_init__(dynamodb_query_result)
            stages = dynamodb_query_result["Stages"]["L"]
            self.setup_run_directory = RegistryEntryStage(
                dynamodb_stage_result=stages[0].get("M", {}) if len(stages) >= 1 else {}
            )
            self.run_simulation_directory = RegistryEntryStage(
                dynamodb_stage_result=stages[1].get("M", {}) if len(stages) >= 2 else {}
            )
        else:
            super().__post_init__(dynamodb_scan_result)
