%% @doc Supervisor для iotserv
%% @end
-module(iotserv_sup).
-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

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