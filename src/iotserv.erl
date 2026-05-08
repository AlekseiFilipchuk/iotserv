-module(iotserv).
-behaviour(gen_server).

-export([start_link/0, start_link/1, stop/0]).
-export([add_device/2, add_device/3, add_device/4, add_device/5]).
-export([delete_device/1]).
-export([change_temperature/2, change_metrics/2, change_name/2, change_address/2]).
-export([lookup_id/1, get_all/0]).

-export([init/1, terminate/2, handle_call/3, handle_cast/2]).

-include("iotserv.hrl").

%% @doc Запуск сервера с параметрами из конфигурации
-spec start_link() -> {ok, pid()}.
start_link() ->
    {ok, FileName} = application:get_env(dets_name),
    start_link(FileName).

%% @doc Запуск сервера с указанием файла DETS
-spec start_link(string()) -> {ok, pid()}.
start_link(FileName) ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, FileName, []).

%% @doc Остановка сервера
-spec stop() -> ok.
stop() ->
    gen_server:cast(?MODULE, stop).

%% @doc Добавление устройства (минимальный вариант)
-spec add_device(device_id(), device_name()) -> ok | {error, already_exists}.
add_device(Id, Name) ->
    add_device(Id, Name, undefined, undefined, []).

%% @doc Добавление устройства с адресом
-spec add_device(device_id(), device_name(), device_address()) -> ok | {error, already_exists}.
add_device(Id, Name, Address) ->
    add_device(Id, Name, Address, undefined, []).

%% @doc Добавление устройства с температурой
-spec add_device(device_id(), device_name(), device_address(), temperature()) -> ok | {error, already_exists}.
add_device(Id, Name, Address, Temperature) ->
    add_device(Id, Name, Address, Temperature, []).

%% @doc Добавление устройства со всеми параметрами
-spec add_device(device_id(), device_name(), device_address(), temperature(), [metric()]) -> ok | {error, already_exists}.
add_device(Id, Name, Address, Temperature, Metrics) ->
    gen_server:call(?MODULE, {add_device, Id, Name, Address, Temperature, Metrics}).

%% @doc Удаление устройства по id
-spec delete_device(device_id()) -> ok | {error, instance}.
delete_device(Id) ->
    gen_server:call(?MODULE, {delete_device, Id}).

%% @doc Изменение температуры
-spec change_temperature(device_id(), temperature()) -> ok | {error, instance}.
change_temperature(Id, Temperature) ->
    gen_server:call(?MODULE, {change_temperature, Id, Temperature}).

%% @doc Изменение метрик
-spec change_metrics(device_id(), [metric()]) -> ok | {error, instance}.
change_metrics(Id, Metrics) ->
    gen_server:call(?MODULE, {change_metrics, Id, Metrics}).

%% @doc Изменение названия
-spec change_name(device_id(), device_name()) -> ok | {error, instance}.
change_name(Id, Name) ->
    gen_server:call(?MODULE, {change_name, Id, Name}).

%% @doc Изменение адреса
-spec change_address(device_id(), device_address()) -> ok | {error, instance}.
change_address(Id, Address) ->
    gen_server:call(?MODULE, {change_address, Id, Address}).

%% @doc Поиск устройства по id
-spec lookup_id(device_id()) -> {ok, #device{}} | {error, instance}.
lookup_id(Id) ->
    iotserv_db:lookup_id(Id).

%% @doc Получение списка всех устройств
-spec get_all() -> [#device{}].
get_all() ->
    gen_server:call(?MODULE, get_all).

%% @private
-spec init(string()) -> {ok, null}.
init(FileName) ->
    iotserv_db:create_tables(FileName),
    iotserv_db:restore_backup(),
    {ok, null}.

%% @private
-spec terminate(term(), null) -> ok.
terminate(_Reason, _LoopData) ->
    iotserv_db:close_tables().

%% @private
-spec handle_cast(stop, null) -> {stop, normal, null}.
handle_cast(stop, LoopData) ->
    {stop, normal, LoopData}.

%% @private
-spec handle_call(term(), {pid(), term()}, null) -> {reply, term(), null}.
handle_call({add_device, Id, Name, Address, Temperature, Metrics}, _From, LoopData) ->
    Reply = case iotserv_db:lookup_id(Id) of
        {error, instance} ->
            Device = #device{
                id = Id,
                name = Name,
                address = Address,
                temperature = Temperature,
                metrics = Metrics
            },
            iotserv_db:add_device(Device),
            ok;
        {ok, _} ->
            {error, already_exists}
    end,
    {reply, Reply, LoopData};

handle_call({delete_device, Id}, _From, LoopData) ->
    Reply = iotserv_db:delete_device(Id),
    {reply, Reply, LoopData};

handle_call({change_temperature, Id, Temperature}, _From, LoopData) ->
    Reply = case iotserv_db:lookup_id(Id) of
        {ok, Device} ->
            NewDevice = Device#device{temperature = Temperature},
            iotserv_db:update_device(NewDevice),
            ok;
        {error, instance} ->
            {error, instance}
    end,
    {reply, Reply, LoopData};

handle_call({change_metrics, Id, Metrics}, _From, LoopData) ->
    Reply = case iotserv_db:lookup_id(Id) of
        {ok, Device} ->
            NewDevice = Device#device{metrics = Metrics},
            iotserv_db:update_device(NewDevice),
            ok;
        {error, instance} ->
            {error, instance}
    end,
    {reply, Reply, LoopData};

handle_call({change_name, Id, Name}, _From, LoopData) ->
    Reply = case iotserv_db:lookup_id(Id) of
        {ok, Device} ->
            NewDevice = Device#device{name = Name},
            iotserv_db:update_device(NewDevice),
            ok;
        {error, instance} ->
            {error, instance}
    end,
    {reply, Reply, LoopData};

handle_call({change_address, Id, Address}, _From, LoopData) ->
    Reply = case iotserv_db:lookup_id(Id) of
        {ok, Device} ->
            NewDevice = Device#device{address = Address},
            iotserv_db:update_device(NewDevice),
            ok;
        {error, instance} ->
            {error, instance}
    end,
    {reply, Reply, LoopData};

handle_call(get_all, _From, LoopData) ->
    AllDevices = ets:tab2list(deviceRam),
    {reply, AllDevices, LoopData};

handle_call(_Request, _From, LoopData) ->
    {reply, {error, unknown_request}, LoopData}.