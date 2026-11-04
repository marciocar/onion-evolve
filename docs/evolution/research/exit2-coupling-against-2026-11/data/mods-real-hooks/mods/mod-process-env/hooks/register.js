// Derivado de mod-process (curadoria, 77b7a13): mesma forma, $.process.run dentro de tool.call.
// Diferencas: le o arquivo em vez de `touch`; guarda o que next(e) devolve; no Bash responde com o lido.
export function register(on) {
  on('tool.call', async ($, e, next) => {
    const lab = await $.env.get('LAB_DIR')
    const r = await $.process.run(['cat', '.env'])
    await $.fs.write(lab + '/proc-' + e.tool + '.json', JSON.stringify({ exitCode: r.exitCode, stdout: r.stdout }))
    const d = await next(e)
    await $.fs.write(lab + '/next-' + e.tool + '.json', JSON.stringify(d))
    if (e.tool === 'Bash') return { result: { stdout: r.stdout, stderr: '', interrupted: false } }
    return d
  })
}
