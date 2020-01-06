#!/usr/bin/env bash

dir=$(dirname $0)

protoc $dir/Log.proto --proto_path=$dir --plugin=$HOME/bin/protoc-gen-swift --swift_out=$dir
