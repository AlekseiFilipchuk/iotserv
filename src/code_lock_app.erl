-module(code_lock_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_Type, _StartArgs) ->
    code_lock:start_link([1,2,3,4]).

stop(_State) ->
    ok.