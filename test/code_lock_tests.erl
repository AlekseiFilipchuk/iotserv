%%%-------------------------------------------------------------------
%%% @doc Тесты для code_lock
%%% @end
%%%-------------------------------------------------------------------
-module(code_lock_tests).
-include_lib("eunit/include/eunit.hrl").

start_stop_test() ->
    {ok, Pid} = code_lock:start_link([1,2,3,4]),
    ?assert(is_pid(Pid)),
    code_lock:stop(Pid),
    ok.

correct_code_test() ->
    {ok, _Pid} = code_lock:start_link([1,2,3]),
    ?assertEqual(ok, code_lock:button(1)),
    ?assertEqual(ok, code_lock:button(2)),
    ?assertEqual(ok, code_lock:button(3)),
    timer:sleep(11000),
    ok.

change_code_test() ->
    {ok, _Pid} = code_lock:start_link([1,2,3,4]),
    code_lock:button(1),
    code_lock:button(2),
    code_lock:button(3),
    code_lock:button(4),
    ?assertEqual(ok, code_lock:change_code([9,9,9,9])),
    timer:sleep(11000),
    ok.

suspension_test() ->
    {ok, _Pid} = code_lock:start_link([1,2,3,4]),
    %% Три неправильные попытки
    code_lock:button(9), code_lock:button(9), code_lock:button(9), code_lock:button(9),
    code_lock:button(9), code_lock:button(9), code_lock:button(9), code_lock:button(9),
    code_lock:button(9), code_lock:button(9), code_lock:button(9), code_lock:button(9),
    timer:sleep(11000),
    ok.