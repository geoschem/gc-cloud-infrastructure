import dataclasses
from .registry_entry_stage import RegistryEntryStage
from .registry_entry import RegistryEntry


@dataclasses.dataclass
class RegistryEntryDiff(RegistryEntry):
    run_gcpy_stage: RegistryEntryStage = None
    emissions_totals_link: str = None
    global_mass_trop_link: str = None
    global_mass_tropstrat_link: str = None
    inventory_totals_link: str = None
    oh_metrics_link: str = None
    dynamodb_query_result: dataclasses.InitVar[dict] = None

    def __post_init__(self, dynamodb_scan_result, dynamodb_query_result):
        if dynamodb_query_result is not None:
            super().__post_init__(dynamodb_query_result)
            stages = dynamodb_query_result["Stages"]["L"]
            self.run_gcpy_stage = RegistryEntryStage(
                dynamodb_stage_result=stages[0].get("M", {}) if len(stages) >= 1 else {}
            )
        else:
            super().__post_init__(dynamodb_scan_result)
