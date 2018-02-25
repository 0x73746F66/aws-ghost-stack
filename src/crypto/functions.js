const autorun = () => {
  const assets = new Map()
  assets.set('header', 'https://gf104f9jf7.execute-api.ap-southeast-2.amazonaws.com/mock/')
  assets.set('menu', 'https://gf104f9jf7.execute-api.ap-southeast-2.amazonaws.com/mock/')
  const tasks = []
  const templates = []
  const views = []

  for (let [tmplName, jsonUrl] of assets.entries()) {
    templates.push(
      fetch(`template/${tmplName}.mustache`)
        .then((response) => response.text())
    )
    views.push(
      fetch(jsonUrl)
        .then((response) => response.json())
    )
  }

  tasks.push(Promise.all(templates))
  tasks.push(Promise.all(views))
  Promise.all(tasks).then(arr => {
    const templatesArr = arr[0]
    const viewsArr = arr[1]

    for (let i = 0, l = [...assets.keys()].length; i < l; i++) {
      const template = templatesArr[i]
      const tmplName = [...assets.keys()][i]
      const json = viewsArr[i]
      console.log('tmplName', tmplName)
      console.log('template', template)
      console.log('json', json)
      const targetEl = document.getElementById(tmplName)
      Mustache.parse(template)
      targetEl.innerHTML = Mustache.render(template, json)
    }
  })
}
const toggleResponsiveMenu = () => {
  const x = document.getElementById('topnav')
  if (x.className === 'topnav') {
    x.className += ' responsive'
  } else {
    x.className = 'topnav'
  }
}