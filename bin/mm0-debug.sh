#!/bin/sh
# Redirect stderr (2) to a file so we can see the panic/logs
mm0-rs server --debug 2>> /tmp/mm0-lsp.log
