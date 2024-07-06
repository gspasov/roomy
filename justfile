set dotenv-load

default: web

help:
  just --list

deps *args:
  mix deps.{{args}}

format:
  mix format

compile:
  mix compile --warnings-as-errors

analyze: compile
  mix dialyzer

build: deps compile

prepare: build
  just ecto setup

server:
  iex -S mix

web:
  iex -S mix phx.server

test *args:
  mix test {{args}}

ecto *args:
  mix ecto.{{args}}

