"""Sonda N2 do taco: o servidor cobra o output_schema declarado na skill?

Declara uma skill estimate (input bom-v1, output estimate-v1), registra um handler
que devolve um payload que NÃO é estimate-v1, e envia um bom vazio (que também não
é bom-v1). Mede: estado final da tarefa e se o payload inválido saiu como artefato.
"""
import asyncio
import json

import httpx
from taco import (A2AServer, ConstructionAgentCard, ConstructionSkill, EstimateV1,
                  make_artifact, make_data_part)


async def main():
    card = ConstructionAgentCard(
        name="Probe", url="http://localhost:9", trade="electrical", csi_divisions=["26"],
        skills=[ConstructionSkill(id="est", name="Est", task_type="estimate",
                                  input_schema="bom-v1", output_schema="estimate-v1")])
    server = A2AServer(card)

    async def bad_handler(task, input_data):
        return make_artifact(parts=[make_data_part({"not": "an estimate", "input_seen": input_data})])

    server.register_handler("estimate", bad_handler)
    payload = {"jsonrpc": "2.0", "id": 1, "method": "message/send", "params": {
        "message": {"role": "user", "parts": [{"kind": "data", "data": {"garbage": True}}], "messageId": "m1"},
        "metadata": {"taskType": "estimate"}}}
    async with httpx.AsyncClient(transport=httpx.ASGITransport(app=server.app), base_url="http://t") as c:
        r = await c.post("/", json=payload)
        body = r.json()
    res = body.get("result", {})
    state = res.get("status", {}).get("state")
    arts = res.get("artifacts") or []
    out = arts[0]["parts"][0].get("data") if arts else None
    try:
        EstimateV1.model_validate(out)
        valid = True
    except Exception:
        valid = False
    print(json.dumps({"state": state, "artifact_data": out, "artifact_is_estimate_v1": valid}, ensure_ascii=False))


asyncio.run(main())
