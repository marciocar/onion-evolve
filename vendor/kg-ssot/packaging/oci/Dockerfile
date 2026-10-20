# A imagem OCI do servidor MCP do KG-SSOT (kg-mcp), para quem o roda como serviço ao lado de um cliente sem Python,
# como o LibreChat. O contexto do build é o diretório que packaging/oci/build.py monta: o wheel da release (o mesmo do
# PyPI) e o tools/requirements.txt, com o hash de cada dependência. Nada é baixado fora do pip, e o pip só instala o
# que bate com o hash.
#
# Por padrão a imagem fala stdio (docker run -i). Para o HTTP no perfil "atrás de proxy", veja o manual
# (docs/manual/05-ferramentas.md, "A imagem OCI").

# python:3.13-slim, fixada por digest; a troca é uma revisão como outra qualquer
FROM python:3.13-slim@sha256:70729b46c69b4f1e97c4822c1af3df53a1476cf5ddc6c087c0c10bc3a5678c2f

ARG VERSION
# o registro MCP confere a posse da imagem por este label, igual ao name do server.json
LABEL io.modelcontextprotocol.server.name="io.github.marciocar/kg-ssot" \
      org.opencontainers.image.title="kg-ssot" \
      org.opencontainers.image.description="Servidor MCP do KG-SSOT: julga e grava .kg.yaml e .kg.json pelo contrato." \
      org.opencontainers.image.source="https://github.com/marciocar/kg-ssot" \
      org.opencontainers.image.documentation="https://github.com/marciocar/kg-ssot/tree/main/docs/manual" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.licenses="Apache-2.0"

COPY requirements.txt kg_ssot-*.whl /tmp/kg/
RUN pip install --no-cache-dir --disable-pip-version-check --require-hashes -r /tmp/kg/requirements.txt \
 && pip install --no-cache-dir --disable-pip-version-check --no-deps /tmp/kg/kg_ssot-*.whl \
 && rm -rf /tmp/kg \
 && groupadd --system --gid 10001 kg \
 && useradd --system --uid 10001 --gid 10001 --home-dir /data --no-create-home kg \
 && mkdir /data && chown 10001:10001 /data

ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
USER 10001:10001
WORKDIR /data
VOLUME /data
ENTRYPOINT ["kg-mcp"]
