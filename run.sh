#!/usr/bin/env bash

docker run -it --rm \
-v $(pwd)/aws:/tmp/ \
-v $(pwd)/credentials:/root/.aws/ \
--entrypoint sh \
hashicorp/terraform:0.11.7