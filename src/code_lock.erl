%%%-------------------------------------------------------------------
%%% @doc Кодовый замок с конечным автоматом (gen_statem)
%%%      Состояния: locked, open, suspended
%%% @end
%%%-------------------------------------------------------------------
-module(code_lock).
-behaviour(gen_statem).

-define(NAME, code_lock).

%% API
-export([start_link/1, button/1, stop/0, change_code/1]).

%% gen_statem callbacks
-export([init/1, callback_mode/0, terminate/3]).
-export([locked/3, open/3, suspended/3]).

%% ============================================================
%% API
%% ============================================================

%% @doc Запускает замок с заданным секретным кодом.
-spec start_link([integer()]) -> gen_statem:start_ret().
start_link(Code) ->
    gen_statem:start_link({local, ?NAME}, ?MODULE, Code, []).

%% @doc Нажатие кнопки.
-spec button(integer()) -> ok.
button(Button) ->
    gen_statem:cast(?NAME, {button, Button}).

%% @doc Остановка замка.
-spec stop() -> ok.
stop() ->
    gen_statem:stop(?NAME).

%% @doc Изменение секретного кода (только в состоянии open).
-spec change_code([integer()]) -> ok | {error, not_open}.
change_code(NewCode) ->
    gen_statem:call(?NAME, {change_code, NewCode}).

%% ============================================================
%% gen_statem callbacks
%% ============================================================

%% @private
-spec init([integer()]) -> gen_statem:init_result(gen_statem:state()).
init(Code) ->
    do_lock(),
    Data = #{
        code => Code,
        length => length(Code),
        buttons => [],
        attempts => 0
    },
    {ok, locked, Data}.

%% @private
callback_mode() ->
    state_functions.

%% @private
%% Состояние locked: ожидаем правильный код
locked(cast, {button, Button}, #{code := Code, length := Length, buttons := Buttons, attempts := Attempts} = Data) ->
    NewButtons =
        if
            length(Buttons) < Length -> Buttons;
            true -> tl(Buttons)
        end ++ [Button],

    if
        %% Код правильный
        NewButtons =:= Code ->
            do_unlock(),
            {next_state, open, Data#{buttons => [], attempts => 0}, [{state_timeout, 10_000, lock}]};

        %% Код неправильный, но неполный (просто сохраняем)
        length(NewButtons) < Length ->
            {next_state, locked, Data#{buttons => NewButtons}, 30_000};

        %% Код неправильный и полный
        true ->
            NewAttempts = Attempts + 1,
            io:format("Wrong code! Attempt ~p/3~n", [NewAttempts]),
            if
                %% 3 неправильные попытки → переходим в suspended
                NewAttempts >= 3 ->
                    io:format("Too many wrong attempts! Lock suspended for 10 seconds.~n", []),
                    {next_state, suspended, Data#{buttons => [], attempts => 0}, [{state_timeout, 10_000, lock}]};
                %% Иначе остаёмся в locked, сбрасываем буфер
                true ->
                    {next_state, locked, Data#{buttons => [], attempts => NewAttempts}, 30_000}
            end
    end;

%% Таймаут 30 секунд без нажатий → сбрасываем буфер
locked(timeout, _, Data) ->
    io:format("Timeout: no button pressed for 30 seconds, clearing buffer~n", []),
    {next_state, locked, Data#{buttons => []}}.

%% @private
%% Состояние open: замок открыт
open(state_timeout, lock, Data) ->
    do_lock(),
    io:format("Door locked after 10 seconds~n", []),
    {next_state, locked, Data#{buttons => []}};

open(cast, {button, _Button}, Data) ->
    {keep_state, Data};

open({call, From}, {change_code, NewCode}, Data) ->
    io:format("Code changed from ~p to ~p~n", [maps:get(code, Data), NewCode]),
    NewData = Data#{code => NewCode, length => length(NewCode)},
    {keep_state, NewData, [{reply, From, ok}]}.

%% @private
%% Состояние suspended: замок заблокирован из-за 3 неудачных попыток
suspended(state_timeout, lock, Data) ->
    io:format("Lock suspension ended, returning to locked state~n", []),
    do_lock(),
    {next_state, locked, Data#{buttons => [], attempts => 0}};

suspended(cast, {button, _Button}, Data) ->
    io:format("Lock is suspended! Please wait...~n", []),
    {keep_state, Data};

suspended({call, From}, {change_code, _NewCode}, _Data) ->
    {keep_state_and_data, [{reply, From, {error, suspended}}]}.

%% @private
-spec terminate(term(), gen_statem:state_name(), term()) -> ok.
terminate(_Reason, State, _Data) ->
    if
        State =/= locked ->
            do_lock();
        true ->
            ok
    end,
    ok.

%% ============================================================
%% Вспомогательные функции
%% ============================================================

do_lock() ->
    io:format("Lock~n", []).

do_unlock() ->
    io:format("Unlock~n", []).