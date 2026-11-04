#!/usr/bin/env python3
# Lê docs/onion/agent-card.json com o SDK oficial do A2A. Uso: a2a_card_parse.py <card.json>
import copy, importlib.metadata as md, json, sys
card = json.load(open(sys.argv[1]))
print("a2a-sdk", md.version("a2a-sdk"), "card.protocolVersion", card.get("protocolVersion"))
from a2a.client.card_resolver import parse_agent_card
try:
    c = parse_agent_card(copy.deepcopy(card))  # a função muta o dict; cópia para não contaminar o parse estrito
    print("parse_agent_card: OK", type(c).__name__, getattr(c, "name", None), "ifaces", len(getattr(c, "supported_interfaces", []) or []))
except Exception as e:
    print("parse_agent_card: ERRO", type(e).__name__, str(e)[:300])
from a2a.types import AgentCard
from google.protobuf import json_format
try:
    json_format.ParseDict(copy.deepcopy(card), AgentCard()); print("ParseDict estrito v1: OK")
except Exception as e:
    print("ParseDict estrito v1: ERRO", type(e).__name__, str(e)[:300])
