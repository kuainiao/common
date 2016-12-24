%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc 通用错误码
%%%
%%% Created : 27. 四月 2016 上午11:35
%%%-------------------------------------------------------------------

-define(ERR_ARG_ERROR,                          51).%%参数格式不正确

%%-assert-----------------------------------------------------------------
-define(ERR_NOT_EXIT_PRO_DICT,                  61).%%进程字段中，不存在该数据
-define(ERR_EXIT_PRO_DICT,                      62).%%进程字段中，已经存在该数据
-define(ERR_NOT_EXIT_PROCESS,                   63).%%不存在该进程
-define(ERR_EXIT_PROCESS,                       64).%%已经存在该进程


%%-binary-----------------------------------------------------------------
-define(ERR_ILLEGAL_CHATS,                      71).%%参数中拥有非法字符<<"\'">>, <<"`">>, <<"\\">>
-define(ERR_SENSITIVE_CHARACTER,                72).%%含有敏感字符


%%-int--------------------------------------------------------------------
-define(ERR_NOT_NATURAL_NUM,                    81).%%不是自然数
-define(ERR_NOT_INTEGER,                        82).%%不是整数

%%-assert-----------------------------------------------------------------
-define(ERR_CONFIG_NO_DATA,                     91).%%没有配置信息

%%-page-----------------------------------------------------------------
-define(ERR_PAGE_MAX_SIZE,                      101).%%页数超过最大限制


%%-type------------------------------------------------------------------
-define(ERR_TYPE_ERROR,             111). %type类型出错
-define(ERR_CONVERT_TYPE_FAIL,      112). %转换类型出错
-define(ERR_CHARS_VERIFY_FAIL,      113). %字符验证出错

