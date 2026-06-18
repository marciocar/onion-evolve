# Fixture de drift de contagem — caso BAD (Regra 16)

Este documento afirma um total divergente da SSOT: o projeto teria
__ONION_COMMANDS_DRIFT__ comandos invocáveis. Como a verdade do filesystem é diferente, a Regra 16
(SOFT) deve flagrar a divergência. O placeholder __ONION_COMMANDS_DRIFT__ é substituído por
(SSOT + offset) no self-test, garantindo divergência sem hardcode frágil.
