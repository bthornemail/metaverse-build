#!/usr/bin/env python3
import sys
import json

def validate(event_json):
    try:
        event = json.loads(event_json)
        actor = event.get('actor', '')
        if 'valid:' in actor:
            return 'OK'
        return 'HALT'
    except:
        return 'HALT'

for line in sys.stdin:
    print(validate(line.strip()))
