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


main() ->
    crypto:start(),
    emysql:start(),
    {ok, Pools} = application:get_env(emysql, pools),
    DBPools = lists:map(
        fun({Pool, Config}) ->
            {_, Database} = lists:keyfind(database, 1, Config),
            {Pool, Database}
        end,
        Pools),
    case DBPools of
        [] -> ok;
        _ ->
            main(DBPools)
    end.

main(Databases) ->
    Fun =
        fun({Pool, Database}) ->
            AllTable = erl_mysql:execute(Pool, <<"select TABLE_NAME from information_schema.`TABLES` where TABLE_SCHEMA = '", (list_to_binary(Database))/binary, "';">>),
            put(pool, Pool),
            lists:map(fun([TableName]) -> table(Pool, TableName) end, AllTable)
        end,
    AllRecord = lists:map(Fun, Databases),
    file:write_file(<<"./src/auto/mysql/mysql_tab_record.hrl">>, AllRecord).


table(Pool, TableName) ->
    Fields = erl_mysql:execute(Pool, <<"SHOW FULL FIELDS  FROM `", TableName/binary, "`;">>),
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
    
    file:make_dir("./src/auto/mysql"),
    file:write_file(<<"./src/auto/mysql/", TableName/binary, ".erl">>, Data),
    Hrl.


to_erl(TableName, OldFields, Fields) ->
    ToRecord = [{Field#field.field, Field#field.default, Field#field.comment} || Field <- Fields],
    ToInsert = [{Field#field.field, Field#field.default, Field#field.comment} || Field <- Fields, Field#field.extra =/= <<"auto_increment">>],
    PRIList = [{Field, ErlType} || #field{field = Field, erl_type = ErlType, key = Key} <- Fields, Key =:= <<"PRI">>],
    OtherList = [{Field, Default} || #field{field = Field, key = Key, default = Default} <- Fields, Key =/= <<"PRI">> andalso Key =/= <<"MUL">> andalso Key =/= <<"UNI">>],
    FieldsRecord = [{K, DataType, TypeSize, IsNull, Default} || #field{field = K, erl_type = DataType, type_size = TypeSize, is_null = IsNull, default = Default} <- Fields],
    {
        [
            to_module(TableName),
            to_field(OldFields),
            to_insert(TableName, ToInsert),
            to_delete(TableName, PRIList),
            to_update(TableName, PRIList, OtherList, ToRecord),
            to_lookup(TableName, ToRecord, PRIList, OtherList),
            to_select(TableName, ToRecord),
            to_validate(),
            to_validate(FieldsRecord),
            to_default(TableName, [{Field#field.field, Field#field.erl_type, Field#field.default, Field#field.comment} || Field <- Fields])
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
