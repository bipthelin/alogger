%% @doc
%% This module is a blank for constructing parse_transformed module that
%% makes actual logging.
%% @end
%% ----------------------------------------------------------------------
%% Copyright (c) 2011 Siberian Fast Food
%% Authors: Alexander Dergachev <alexander.dergachev@gmail.com>
%%          Artem Golovinsky    <artemgolovinsky@gmail.com>
%%          Igor Karymov        <ingham.k@gmail.com>
%%          Dmitry Groshev      <lambdadmitry@gmail.com>
%
%% The contents of this file are subject to the Erlang Public License,
%% Version 1.1, (the "License"); you may not use this file except in
%% compliance with the License. You should have received a copy of the
%% Erlang Public License along with this software. If not, it can be
%% retrieved online at http://www.erlang.org/.
%%
%% Software distributed under the License is distributed on an "AS IS"
%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
%% the License for the specific language governing rights and limitations
%% under the License.
%% ----------------------------------------------------------------------

-module(alog_if_default).

-compile([{parse_transform, alog_parse_trans}, nowarn_unused_vars]).
-include("alog.hrl").
-export([log/7,
	 log_lazy/7,
         default_mod_ast/0,
         default_modlogs_ast/0]).

%% @doc Will return list of {Formatter,loggers} for module/tag
get_mod_logs(_, _, _, _) -> 
    {ok,[]}.

%% @doc Main logging function
log(Format, Args, Level, Tags, Module, Line, Pid)
    when is_list(Tags), Tags /= [] ->
    [log(Format, Args, Level, Tag, Module, Line, Pid)
     || Tag <- Tags],
    ok;
log(Format, Args, Level, Tag, Module, Line, Pid) ->
    to_log(Format, Args, Level, Tag,  Module, Line, Pid, now(), get_loggers(Level, Module, Tag)).    

%% @doc Helpful log function
to_log(Format, Args, Level, Tag,  Module, Line, Pid, Time, [{_, []}|TailLoggers]) ->
    to_log(Format, Args, Level, Tag,  Module, Line, Pid, Time, TailLoggers);

to_log(Format, Args, Level, Tag,  Module, Line, Pid, Time, [{Formatter, Loggers}|TailLoggers]) ->
    Formatted = Formatter:format(Format, Args, Level, Tag, Module, Line, Pid, Time),
    [Logger:log(Level, Formatted)  || Logger <- Loggers],
    to_log(Format, Args, Level, Tag,  Module, Line, Pid, Time, TailLoggers);    

to_log(_, _, _, _, _, _, _, _, []) ->
    ok.

%% @doc Helpful "lazy" log function. Fun from args will be executed.
%%      expensive operation 
log_lazy(Format, Args, Level, Tag, Module, Line, Pid) ->
    to_log_lazy(Format, Args, Level, Tag,  Module, Line, Pid, now(), get_loggers(Level, Module, Tag)).

to_log_lazy(Format, Args, Level, Tag,  Module, Line, Pid, Time, [{_, []}|TailLoggers]) ->
    to_log_lazy(Format, Args, Level, Tag,  Module, Line, Pid, Time, TailLoggers);

to_log_lazy(Format, Args, Level, Tag,  Module, Line, Pid, Time, [{Formatter, Loggers}|TailLoggers]) ->
    DecFun = fun(MyFun) when is_function(MyFun) ->
		     MyFun();
		(Variable) ->
		     Variable
	      end,
    Formatted = Formatter:format(Format, [DecFun(F) || F <- Args], 
				 Level, Tag, Module, Line, Pid, Time),
    [Logger:log(Level, Formatted)  || Logger <- Loggers],
    to_log_lazy(Format, Args, Level, Tag,  Module, Line, Pid, Time, TailLoggers);
    
to_log_lazy(_, _, _, _, _, _, _, _, []) ->
    ok.

%% @doc Get all loggers as list of lists 
get_loggers(Level, Module, Tag) ->
    [get_mod_logs(Flow, Level, Module, Tag) || Flow <- flows()].

%% @doc Return list of flows, which should be logged
flows() ->
    [].

%% @doc Will return default AST of this module after parse_transform
default_mod_ast() ->
    ok.

%% @doc Will return default AST of get_logs_mod/3
default_modlogs_ast() ->
    ok.
