-module(iotserv_sup).
-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

-spec start_link() -> {ok, pid()}.
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

-spec init([]) -> {ok, {supervisor:sup_flags(), [supervisor:child_spec()]}}.
init([]) ->
    IoTServChild = {
        iotserv,
        {iotserv, start_link, []},
        permanent,
        2000,
        worker,
        [iotserv, iotserv_db]
    },
    {ok, {{one_for_all, 1, 1}, [IoTServChild]}}.