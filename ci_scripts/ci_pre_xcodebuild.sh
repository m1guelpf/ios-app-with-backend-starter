#!/bin/sh

plutil -replace {{NAME}}BackendURL -string $BACKEND_URL ../app/Info.plist
