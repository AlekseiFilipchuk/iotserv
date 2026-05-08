-module(iotserv_db).
-include("iotserv.hrl").

-export([create_tables/1, close_tables/0, add_device/1, update_device/1, delete_device/1,
         lookup_id/1, restore_backup/0, delete_all/0]).

-define(DEVICE_RAM, deviceRam).
-define(DEVICE_DISK, deviceDisk).

%% @doc Создание таблиц при инициализации
-spec create_tables(string()) -> ok.
create_tables(FileName) ->
    ets:new(?DEVICE_RAM, [named_table, {keypos, #device.id}]),
    dets:open_file(?DEVICE_DISK, [{file, FileName}, {keypos, #device.id}]),
    ok.

%% @doc Закрытие таблиц при остановке
-spec close_tables() -> ok.
close_tables() ->
    ets:delete(?DEVICE_RAM),
    dets:close(?DEVICE_DISK),
    ok.

%% @doc Добавление нового устройства
-spec add_device(#device{}) -> ok.
add_device(Device) ->
    update_device(Device).

%% @doc Обновление устройства (синхронно в ETS и DETS)
-spec update_device(#device{}) -> ok.
update_device(Device) ->
    ets:insert(?DEVICE_RAM, Device),
    dets:insert(?DEVICE_DISK, Device),
    ok.

%% @doc Поиск устройства по id
-spec lookup_id(device_id()) -> {ok, #device{}} | {error, instance}.
lookup_id(Id) ->
    case ets:lookup(?DEVICE_RAM, Id) of
        [Device] -> {ok, Device};
        [] -> {error, instance}
    end.

%% @doc Удаление устройства по id
-spec delete_device(device_id()) -> ok | {error, instance}.
delete_device(Id) ->
    case lookup_id(Id) of
        {ok, Device} ->
            dets:delete(?DEVICE_DISK, Device#device.id),
            ets:delete(?DEVICE_RAM, Device#device.id),
            ok;
        {error, instance} ->
            {error, instance}
    end.

%% @doc Восстановление данных из DETS при запуске
-spec restore_backup() -> ok.
restore_backup() ->
    Insert = fun(Device) ->
        ets:insert(?DEVICE_RAM, Device),
        continue
    end,
    dets:traverse(?DEVICE_DISK, Insert).

%% @doc Удаление всех устройств
-spec delete_all() -> ok.
delete_all() ->
    ets:delete_all_objects(?DEVICE_RAM),
    dets:delete_all_objects(?DEVICE_DISK),
    ok.