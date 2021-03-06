ERL ?= erl
APP := alog

.PHONY: deps

all: deps compile

compile:
	@./rebar compile

debug:
	@./rebar debug_info=1 compile

deps:
	@./rebar get-deps

app:
	@./rebar compile skip_deps=true

webstart: app
	exec erl -pa $(PWD)/ebin -pa $(PWD)/deps/*/ebin -boot start_sasl -config $(PWD)/priv/app.config -s $(APP)

clean:
	@./rebar clean

distclean: clean
	@./rebar delete-deps

test:
	@./rebar compile skip_deps=true eunit

docs:
	@erl -noshell -run edoc_run application '$(APP)' '"."' '[]'
