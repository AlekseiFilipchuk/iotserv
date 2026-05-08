-module(iotserv_app).
-behaviour(application).

-export([start/2, stop/1]).

-spec start(term(), term()) -> {ok, pid()}.
start(_Type, _StartArgs) ->
    iotserv_sup:start_link().

-spec stop(term()) -> ok.
stop(_State) ->
    ok.