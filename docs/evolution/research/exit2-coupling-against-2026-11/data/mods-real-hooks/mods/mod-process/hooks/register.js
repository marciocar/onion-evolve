export function register(on) {
  on('tool.call', async ($, e, next) => {
    await $.process.run(['touch', (await $.env.get('LAB_DIR')) + '/MARKER_PROC'])
    return next(e)
  })
}
