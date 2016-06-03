%#!/usr/bin/env escript
%% -*- erlang -*-
%%! -smp enable -I include/
%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%%   emysql 返回值目前发现只有两种类型 1.int 2.binary
%%%         PRI主键约束；
%%%         UNI唯一约束；
%%%         MUL可以重复。
%%%
%%% select  1.根据主键/联合主键查
%%%         2.组装select条件查询（返回100条匹配的数据）
%%%
%%% 复杂查询自己写sql语句
%%%
%%%
%%% Created : 16. 五月 2016 上午11:35
%%%-------------------------------------------------------------------
-module(emysql_extra).

-compile(export_all).

-include("emysql_to_html.hrl").

-record(field, {
    field,      %
    type,
    erl_type,
    type_size,
    collation,
    is_null,
    key,
    default, %如果是undefined
    extra,
    privileges,
    comment
}).

main(_Arg) ->
    crypto:start(),
    emysql:start(),
    {ok, Pools} = application:get_env(emysql, pools),
    Fun = fun({_, Config}) ->
        {_, Database} = lists:keyfind(database, 1, Config),
        AllTable = erl_mysql:execute(<<"select TABLE_NAME from information_schema.`TABLES` where TABLE_SCHEMA = '", (list_to_binary(Database))/binary, "'">>),
        AllRecord = lists:map(fun([TableName]) -> table(TableName) end, AllTable),
        file:write_file(<<"./src/auto/mysql/mysql_tab_record.hrl">>, AllRecord)
          end,
    lists:map(Fun, Pools).


table(TableName) ->
    Fields = erl_mysql:execute(<<"SHOW FULL FIELDS  FROM `platform_info`.`", TableName/binary, "`;">>),
    Fun =
        fun([Field, Type, _Encode, IsNull, Index, Default, _Extra, _Privileges, _Comment]) ->
            {DataType, TypeSize} = check_type(Type),
            NewDefault = if
                             Default =:= undefined -> <<"''">>;
                             is_binary(Default) -> Default
                         end,
            #field{field = Field, type = Type, erl_type = DataType,
                type_size = TypeSize, collation = _Encode,
                is_null = IsNull, key = Index, default = NewDefault,
                extra = _Extra, privileges = _Privileges, comment = _Comment}
        end,
    NewFields = lists:map(Fun, Fields),
    {Data, Hrl} = to_erl(TableName, Fields, NewFields),

    os:cmd("mkdir -p ./src/auto/mysql"),
    file:write_file(<<"./src/auto/mysql/", TableName/binary, ".erl">>, Data),
    Hrl.


to_erl(TableName, OldFields, Fields) ->
    ToRecord = [{Field#field.field, Field#field.default, Field#field.comment} || Field <- Fields],
    PRIList = [{Field, Default} || #field{field = Field, key = Key, default = Default} <- Fields, Key =:= <<"PRI">> orelse Key =:= <<"MUL">> orelse Key =:= <<"UNI">>],
    OtherList = [{Field, Default} || #field{field = Field, key = Key, default = Default} <- Fields, Key =/= <<"PRI">> andalso Key =/= <<"MUL">> andalso Key =/= <<"UNI">>],
    FieldsRecord = [{K, DataType, TypeSize, IsNull, Default} || #field{field = K, erl_type = DataType, type_size = TypeSize, is_null = IsNull, default = Default} <- Fields],
    {
        [
            to_module(TableName),
            to_field(OldFields),
            to_insert(TableName, ToRecord),
            to_delete(TableName, PRIList),
            to_update(TableName, PRIList, OtherList),
            to_lookup(TableName, ToRecord, PRIList, OtherList),
            to_check_fields(TableName, ToRecord),
            to_validate(),
            to_validate(FieldsRecord)
        ],
        to_record(TableName, ToRecord)
    }.


%% 目前只识别常用的格式
%%int -2^31 (-2,147,483,648) 到 2^31 - 1 (2,147,483,647) 的整型数据
-define(ALL_TYPE, [<<"int">>, <<"char">>, <<"varchar">>, <<"binary">>]).
-spec check_type(DataType :: binary()) -> {int, integer()} | {binary, integer()}.
check_type(DataType) ->
    case binary:match(DataType, <<"int">>) of
        nomatch ->
            check_type(?ALL_TYPE, DataType);
        _ ->
            {int, 0}
    end.

check_type([], _) -> {binary, null};
check_type([Type | Types], DataType) ->
    case binary:match(DataType, Type) of
        {0, Len} ->
            {binary, binary:part(DataType, Len + 1, byte_size(DataType) - Len - 2)};
        _ ->
            check_type(Types, DataType)
    end.
