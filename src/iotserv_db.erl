%% @doc Модуль для работы с хранилищем (ETS + DETS)
%% @end
-module(iotserv_db).
-include("iotserv.hrl").

-export([create_tables/1, close_tables/0, add_device/1, update_device/1, delete_device/1,
         lookup_id/1, restore_backup/0, delete_all/0]).

-define(DEVICE_RAM, deviceRam).
-define(DEVICE_DISK, deviceDisk).

create_tables(FileName) ->
    ets:new(?DEVICE_RAM, [named_table, {keypos, #device.id}]),
    dets:open_file(?DEVICE_DISK, [{file, FileName}, {keypos, #device.id}]),
    ok.

close_tables() ->
    ets:delete(?DEVICE_RAM),
    dets:close(?DEVICE_DISK),
    ok.

add_device(Device) ->
    update_device(Device).

update_device(Device) ->
    ets:insert(?DEVICE_RAM, Device),
    dets:insert(?DEVICE_DISK, Device),
    ok.

lookup_id(Id) ->
    case ets:lookup(?DEVICE_RAM, Id) of
        [Device] -> {ok, Device};
        [] -> {error, instance}
    end.

delete_device(Id) ->
    case lookup_id(Id) of
        {ok, Device} ->
            dets:delete(?DEVICE_DISK, Device#device.id),
            ets:delete(?DEVICE_RAM, Device#device.id),
            ok;
        {error, instance} ->
            {error, instance}
    end.

restore_backup() ->
    Insert = fun(Device) ->
        ets:insert(?DEVICE_RAM, Device),
        continue
    end,
    dets:traverse(?DEVICE_DISK, Insert).

delete_all() ->
    ets:delete_all_objects(?DEVICE_RAM),
    dets:delete_all_objects(?DEVICE_DISK),
    ok.