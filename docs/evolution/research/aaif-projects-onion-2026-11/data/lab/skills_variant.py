#!/usr/bin/env python3
# Copia as skills e aplica uma variante no frontmatter, só na cópia.
# Uso: skills_variant.py <dir-skills-copia> name|name+block
# name: acrescenta name igual ao diretório. name+block: também reescreve paths: [..] como lista em bloco.
import pathlib, re, sys
root, mode = pathlib.Path(sys.argv[1]), sys.argv[2]
for p in root.glob("*/SKILL.md"):
    s = p.read_text()
    m = re.match(r"---\n(.*?)\n---\n", s, re.S)
    fm = m[1]
    if not re.search(r"^name:", fm, re.M):
        fm = f"name: {p.parent.name}\n" + fm
    if mode == "name+block":
        fm = re.sub(r"^paths: \[(.*)\]$",
                    lambda x: "paths:\n" + "\n".join(f'  - "{i}"' for i in re.findall(r'"([^"]+)"', x[1])),
                    fm, flags=re.M)
    p.write_text("---\n" + fm + "\n---\n" + s[m.end():])
