"""Sonda da revisão adversarial: card A2A comum (sem x-construction) e taskType code-review; mede se a camada genérica do taco serve tarefa fora da construção."""
import asyncio
import json

import httpx
from taco import A2AServer, make_artifact, make_data_part
from taco.types import AgentCapabilities, AgentCard, AgentSkill

card = AgentCard(name="Plain", description="d", url="http://l:9", version="1",
                 capabilities=AgentCapabilities(), default_input_modes=["application/json"],
                 default_output_modes=["application/json"],
                 skills=[AgentSkill(id="cr", name="cr", description="d", tags=["code-review"])])
server = A2AServer(card)


async def h(task, inp):
    return make_artifact(parts=[make_data_part({"ok": True, "inp": inp})])

server.register_handler("code-review", h)


async def main():
    p = {"jsonrpc": "2.0", "id": 1, "method": "message/send", "params": {
        "message": {"role": "user", "parts": [{"kind": "data", "data": {"diff": "x"}}], "messageId": "m"},
        "metadata": {"taskType": "code-review"}}}
    async with httpx.AsyncClient(transport=httpx.ASGITransport(app=server.app), base_url="http://t") as c:
        r = (await c.post("/", json=p)).json()
    res = r.get("result", {})
    arts = res.get("artifacts") or [{}]
    print(json.dumps({"state": res.get("status", {}).get("state"), "art": arts[0].get("parts"), "err": r.get("error")}))

asyncio.run(main())
