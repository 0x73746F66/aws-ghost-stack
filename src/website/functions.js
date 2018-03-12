const isValidUrl = string => {
  try {
    new URL(string)
    return true
  } catch (_) {
    return false
  }
}
const prepareTemplates = (assets, partials = {}) => {
  if (assets && !(assets instanceof Map)) {
    throw new Error('problem loading page templates')
  }
  if (!assets) {
    assets = new Map
    assets.set('footer', '')
    assets.set('menu', { page: {
        about: activePage === 'about',
        contact: activePage === 'contact',
        index: activePage === 'index',
        services: activePage === 'services'
      }
    })
  }
  const tasks = []
  const templates = []
  const views = []

  for (let [tmplName, jsonUrl] of assets.entries()) {
    templates.push(
      fetch(`template/${tmplName}.mustache`)
        .then((response) => response.text())
    )
    if (isValidUrl(jsonUrl) || (typeof jsonUrl === 'string' && jsonUrl.charAt(0) === '/')) {
      views.push(
        fetch(jsonUrl)
          .then((response) => response.json())
      )
    } else {
      views.push(Promise.resolve(jsonUrl || null))
    }
  }
  tasks.push(Promise.all(templates))
  tasks.push(Promise.all(views))
  return Promise.all(tasks).then(arr => {
    const templatesArr = arr[0]
    const viewsArr = arr[1]
    const ret = {}

    for (let i = 0, l = [...assets.keys()].length; i < l; i++) {
      const template = templatesArr[i]
      const tmplName = [...assets.keys()][i]
      const json = viewsArr[i]
      Mustache.parse(template)
      ret[tmplName] = Mustache.render(template, json, partials)
    }
    return Promise.resolve(ret)
  })
}
const renderTemplates = templates => Object.keys(templates).forEach(tmplName => {
  console.log('tmplName', tmplName)
  const targetEl = document.getElementById(tmplName)
  targetEl.innerHTML = templates[tmplName]
})
const toggleResponsiveMenu = () => {
  const x = document.getElementById('topnav')
  if (x.className === 'topnav') {
    x.className += ' responsive'
  } else {
    x.className = 'topnav'
  }
}
//########## Pages init ##########//
const autorunContact = () => {
  $(document).on('click', '#contact-us-form button', event => {
    $(event.originalEvent.target).hide()
    $('.sending').show()
  })
  prepareTemplates().then(partials => {
    $('.loader-ring').remove()
    const assets = new Map()
    assets.set('contact', '/config.json')
    prepareTemplates(assets, partials).then(renderTemplates)
  })
}
const autorunHome = () => {
  prepareTemplates().then(partials => {
    $('.loader-ring').remove()
    const assets = new Map()
    assets.set('home', '/config.json')
    prepareTemplates(assets, partials).then(renderTemplates)
  })
}
const autorunServices = () => {
  prepareTemplates().then(partials => {
    $('.loader-ring').remove()
    const assets = new Map()
    assets.set('services', '/config.json')
    prepareTemplates(assets, partials).then(renderTemplates)
  })
}
const autorunAbout = () => {
  prepareTemplates().then(partials => {
    $('.loader-ring').remove()
    const assets = new Map()
    assets.set('about', '/config.json')
    prepareTemplates(assets, partials).then(renderTemplates)
  })
}
//########## Contact Request ##########//
const onContctUsSubmit = () => {
  $('.thanks').hide()
  $('.sending').hide()
  $('.errors').hide()

  if ($('#contact-us-form input[name="name"]').val() === '' ||
      $('#contact-us-form input[name="email"]').val() === '') {
      $('.errors').show()
      $('#contact-us-form button').show()
  } else {
      $('.errors').hide()
      fetch($('#contact-us-form').attr('action'), {
        method: 'post',
        body: JSON.stringify({
          name: $('#contact-us-form input[name="name"]').val(),
          email: $('#contact-us-form input[name="email"]').val(),
          phone: $('#contact-us-form input[name="phone"]').val(),
          message: $('#contact-us-form textarea[name="message"]').val(),
          'g-recaptcha-response': $('#contact-us-form textarea[name="g-recaptcha-response"]').val()
      })
      }).then(response => response.json()).then(() => {
        $('.thanks').show()
        $('#contact-us-form button').hide()
        $('#contact-us-form input[name="name"]').val('')
        $('#contact-us-form input[name="email"]').val('')
        $('#contact-us-form input[name="phone"]').val('')
        $('#contact-us-form textarea[name="message"]').val('')
    })
  }
}