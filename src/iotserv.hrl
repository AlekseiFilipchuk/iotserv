-type device_id() :: integer().
-type device_name() :: binary().
-type device_address() :: binary().
-type temperature() :: float().
-type metric_key() :: water_consumption | temp | mem_load | atom().
-type metric_value() :: number().
-type metric() :: {metric_key(), metric_value()}.

-export_type([device_id/0, metric/0]).

-record(device, {
    id          :: device_id(),
    name        :: device_name(),
    address     :: device_address(),
    temperature :: temperature() | undefined,
    metrics     :: [metric()] | []
}).