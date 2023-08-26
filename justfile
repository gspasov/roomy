default: web

help:
  just --list

deps:
  mix deps.get

compile:
  mix compile

analyze: compile
  mix dialyzer

build: deps compile analyze

server:
  iex -S mix

web:
  iex -S mix phx.server

test *args:
  mix test {{args}}

prepare: build
  mix ecto.setup

reset:
  mix ecto.reset

migrate *args:
  mix ecto.migrate {{args}}

