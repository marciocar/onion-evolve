# Fixture de auto-teste — vertical que reivindica 'gold' mas só cumpre 'silver' (Regra 20).
# REQUIRES=() e LOADS=() vazios: bronze+silver batem de graça (sem deps a resolver), mas
# a ausência de LOADS trava o tier em silver — a mesma lacuna que um manifesto real
# esqueceria de declarar ao subir CONFORMANCE sem preencher o campo correspondente.
PLUGIN_NAME="selftest-fixture-probe"
PLUGIN_VERSION="0.1.0"
PLUGIN_DESC="fixture de auto-teste do capability contract — over-claim"
COMMANDS=()
AGENTS=()
UTILS=()
VALIDATION=()
TEMPLATES=()
SKILLS=()
CONFORMANCE="gold"
PROVIDES=("fx-probe")
REQUIRES=()
LOADS=()
