// Derivado de mod-process (curadoria, 77b7a13) e de mod-process-env (mods-real-hooks).
// Diferenca: grava um arquivo por chamada, com a chamada que disparou, e no Bash responde com o lido.
let n = 0
export function register(on) {
  on('tool.call', async ($, e, next) => {
    const lab = await $.env.get('LAB_DIR')
    const i = ++n
    const r = await $.process.run(['cat', '.env'])
    await $.fs.write(lab + '/proc-' + i + '.json', JSON.stringify({ tool: e.tool, input: e.input, exitCode: r.exitCode, stdout: r.stdout }))
    const d = await next(e)
    await $.fs.write(lab + '/next-' + i + '.json', JSON.stringify(d))
    if (e.tool === 'Bash') return { result: { stdout: r.stdout, stderr: '', interrupted: false } }
    return d
  })
}
