R = React.DOM
cx = React.addons.classSet
$ = Zepto


# Hashed qs
# Handles strings and arrays
# Anything with a comma will be parsed as an array
qs =
  merge: (obj)->

  get: (field)->
  
  set: (field, val)->
    qsObj = @toObj() || {}
    qsObj[field] = val
    @setQS @toQS(qsObj)

  delete: (field)->
    qsObj = @toObj() || {}
    return if not qsObj?
    delete qsObj[field]
    @setQS @toQS qsObj

  encodeCharsIn: ['=','&']

  encodeCharsOut:['%3D','%26']

  encode: (obj)->
    if _.isArray obj
      obj = obj.join(',')
    obj.replace(@encodeCharsIn, @encodeCharsOut)

  decode: (str)->
    str = str.replace(@encodeCharsOut, @encodeCharsIn)
    if str.indexOf(',') != -1
      str = str.split(',')
    str


  toObj: (qs = window.location.hash.split('?')?[1])->
    if not qs
      return
    out = {}
    pairs = qs.split('&')
    pairs?.forEach (pair)=>
      kvArr = pair.split('=')
      out[@decode(kvArr[0])] = @decode(kvArr[1])
    out

  toQS: (obj)->
    pairs = []
    for own k,v of obj
      pairs.push "#{@encode(k)}=#{@encode(v)}"
    pairs.join('&')
       
  setQS: (qs)->
    window.location.hash = window.location.hash.split('?')[0] + '?' + qs
 

$app = document.getElementById 'app'




cardClassName = (props) ->
  ownerClass = "owner-#{props.owner}"
  classes = cx
    'asiaScoring': props.title == 'Asia Scoring'
    'europeScoring': props.title == 'Europe Scoring'
    'middleEastScoring': props.title == 'Middle East Scoring'
    'centralAmericaScoring': props.title == 'Central America Scoring'
    'southeastAsiaScoring': props.title == 'Southeast Asia Scoring*'
    'africaScoring': props.title == 'Africa Scoring'
    'southAmericaScoring': props.title == 'South America Scoring'
    'ongoing': props.ongoing

  ownerClass + ' ' + classes

cardStage = (stage) ->
  return 'EARLY' if stage == 1
  return 'MID' if stage == 2
  return 'LATE'

zeroPad = (str, len=3) ->
 ('000' + str).substr(-len,len)

sortNumerical = (a,b)-> a-b

Card = React.createClass
  render: ->
    R.div className: cardClassName(@props) + ' card', [
      R.a {className: 'card-title-holder', href: "#/card/#{@props.id}"}, [
        R.span className: 'card-stage', cardStage @props.stage
        R.h4 className: 'card-ops', if @props.ops < 1 then "S" else @props.ops
        R.h4 className: 'card-title', @props.title
      ]
      R.p className: 'card-text', @props.text
    ]


CardList = React.createClass
  render: ->
    className = cx
      'cardList': true
      'cardListFull': @props.fullText
    R.div {className}, @props.cards.map (el) =>
      Card _.merge el, showFullText: @props.fullText


CardsView = React.createClass
  defaultState: (props)->
    fullText: if props?.state?.filter then true else false
    sort: 'stage'
    filter: null

  componentWillReceiveProps: (nextProps) ->
    if nextProps.state?
      @setState nextProps.state
    else
      @setState @defaultState()

  getInitialState: ->
    _.merge @defaultState(@props), @props.state

  getFilterIds: () ->
    if @state?.filter?
      return @state.filter.sort sortNumerical

  # Just filtering by id right now
  getFilteredCards: ->
    if @state.filter?
      return @props.cards.filter (el) =>
        if el.id in @state.filter
          return el
    @props.cards
        

  filterAndSortCards: ->
    cards = @getFilteredCards()
    [sort, order] = @state.sort.split '-'

    sortParam = switch sort
      when 'textlen' then (el) -> el.text.length
      when 'side' then ['owner','stage','id']
      when 'ops' then 'ops'
      when 'titlelen' then (el) -> el.title.length
      else ['stage', 'id']
    cards = _.sortBy cards, sortParam

    if order == 'rev'
      cards.reverse()

    cards


  handleFullText: ->
    @setState
      fullText: @refs.fullText.getDOMNode().checked

  handleCardFilterChange: ->
    value = @refs.cardFilter.getDOMNode().value
    # WGR adds "Ops 3: ...", so don't pick those up
    ids = value.match(/\d+[^:]|\d+$/g)?.map (el)-> parseInt el, 10
    if value == '' or not ids?
      @setState
        filter: null
        cardFilterInput: ''
      return

    @setState
      cardFilterInput: value
      fullText: true
      filter: ids.sort sortNumerical

  handleCardFilterBlur: ->
    filterIds = @getFilterIds()
    
    @setState
      cardFilterInput: filterIds
    if filterIds?
      qs.set 'filter', filterIds
    else
      qs.delete 'filter'

  handleCardFilterClear: ()->
    @refs.cardFilter.getDOMNode().value = ''
    @setState
      filter:null
      cardFilterInput: ''

    qs.delete 'filter'



  render: ->
    sortLink = (sort, display) =>
      className = cx active: @state.sort == sort
      ref = "#{sort}Sort"
      onClick = ()->
        qs.set 'sort', sort
      R.a {onClick, ref, className}, display


    R.div className: 'cardsView' , [
      R.div className: 'page-header', [
        R.h2 {}, 'Cards'
        " "
        R.div className: 'cardControls sortBy pull-left', [
          R.strong {}, 'Sort by:'
          sortLink 'stage', 'Stage'
          sortLink 'ops', 'Ops'
          sortLink 'side', 'Side'
        ]
        R.input
          name: 'fullText'
          id: 'fullText'
          type:'checkbox'
          ref:'fullText'
          onChange: @handleFullText
          checked: @state.fullText
        " "
        R.label {htmlFor:'fullText'}, 'Show card text'
        R.div className: 'cards-filter-by-id', [
          R.label {htmlFor:'cardFilter'}, [
            "Filter cards by ids "
            R.a {className:'cards-filter-by-id-clear', onClick:@handleCardFilterClear}, 'clear'
          ]
          R.input
            name: 'cardFilter'
            type: 'text'
            ref: 'cardFilter'
            onChange: @handleCardFilterChange
            onBlur: @handleCardFilterBlur
            value: @state.cardFilterInput
            placeholder: 'Paste from WarGameRoom or enter ids'
        ]
      ]
      CardList
        cards: @filterAndSortCards()
        fullText: @state.fullText
    ]


AboutView = React.createClass
  render: ->
    R.div className: 'aboutView', [
      R.div className: 'page-header',
        R.h2 {}, "About TwiStrug"
      R.img className: 'imgRight', src: "/images/tsbox.jpg"
      R.p {}, [
        "TwiStrug is for people who want to learn more about the
        cards of "
        R.a href:"http://en.wikipedia.org/wiki/Twilight_Struggle",
          "Twilight Struggle"
        " in a zippy web app."
      ]
      R.p {}, [
        "For more in-depth strategy, go to the excellent "
        R.a href: "http://twilightstrategy.com", "Twilight Strategy"
        " site. It has tons of great content and
        analysis available, including discussions about nearly every card.
        Please support Twilight Strategy and its author, "
        R.em {}, "theory"
        ", by purchasing Twilight Strugle from Amazon on the sidebar of the
        site."
      ]
    ]
    

CardView = React.createClass
  componentDidMount: ->
    @getStrategy()
    @setWindowKeypressHandler()

  componentDidUpdate: ->
    @getStrategy()
    @setWindowKeypressHandler()

  setWindowKeypressHandler: ->
    window.onkeypress = (ev) =>
      kC = ev.keyCode
      if kC == 104 or kC == 72
        id = @props.prevCard.id
      if kC == 108 or kC == 76
        id = @props.nextCard.id
      if id?
        window.location = "#/card/#{id}"

  getStrategy: ->
    @refs.cardStrategy.getDOMNode().innerHTML = '<p>Loading data...</p>'
    $.get "/data/cardStrategyLinked/#{zeroPad(@props.card.id)}.html", (data)=>
      @refs.cardStrategy.getDOMNode().innerHTML = data

  render: ->
    card = @props.card
    imageUrl = "/images/cards/#{zeroPad(card.id)}.jpg"
    R.div className: 'cardView', [
      R.div className: 'page-header clearfix',
        R.h2 className: cardClassName(card), [
          R.span className:'card-ops', if card.ops < 1 then "S" else card.ops
          card.title
        ]
        R.div className: 'card-nav', [
          R.a {href:"#/card/#{@props.prevCard.id}", className:'card-nav-prev'}, [
            "#{@props.prevCard.title}"
            R.span className: 'card-nav-label', [
              R.small {}, '◀'
              ' prev (H)'
            ]
          ]
          R.a {href:"#/card/#{@props.nextCard.id}", className:'card-nav-next'}, [
            "#{@props.nextCard.title}"
            R.span className: 'card-nav-label', [
              'next (L) '
              R.small {}, '▶'
            ]
          ]
        ]
      R.img src: imageUrl, className: 'imgRight'
      R.p {}, card.text
      R.div {className: 'card-strategy', id: 'card-strategy'}, [
        R.h3 {}, [
          'Strategic Notes from'
          ' '
          R.a href:card.url, 'TwilightStrategy.com'
        ]
        R.div ref:'cardStrategy',
          R.p {}, 'Loading data'
      ]
    ]


CountriesView = React.createClass
  render: ->
    R.div className: 'countriesView', [
      R.h2 {}, 'Countries'
    ]

BoardView = React.createClass
  render: ->
    R.div className: 'boardView', [
      R.div className: 'page-header',
        R.h2 {}, 'Board'
      R.a href:'/images/tsboard.jpg',
        R.img className: 'fluid', src:'/images/tsboard.jpg'
    ]



WhoopsView = React.createClass
  render: ->
    R.div {}, [
      R.h2 {}, "DEFCON 1"
      R.p className:'lead', [
        "Looks like TwiStrug triggered nuclear war. WHOOPSIE DAISY!"
        R.br {}
        R.a href:"#/cards", "How about looking over the cards?"
      ]
    ]

HomeView = React.createClass
  render: ->
    R.div {}, [
      R.p className:'lead', [
        "TwiStrug is a companion application for "
        R.a href:"http://en.wikipedia.org/wiki/Twilight_Struggle", "Twilight Struggle"
        ". It would not exist without "
        R.a href: "http://twilightstrategy.com", "Twilight Strategy"
        "."
      ]
      CardsView cards: @props.cards
    ]

# Main application component
# Responsible for routing and view management
TwiStrug = React.createClass
  # Takes a view name and associated data
  setView: (name, data={}) ->
    @setState view: {name, data}

  componentDidMount: ->
    router = new Router
      #'':
        #@setView.bind this, 'home'
      #'/cards':
        #'': @setView.bind this, 'cards'
        #'/sort/:sort': (sort) =>
          #@setView 'cards',
            #sort: sort
      '/board': @setView.bind this, 'board'
      '/card/:id': (id) =>
        id = +id
        nextId = if id == 110 then 1 else id + 1
        prevId = if id == 1 then 110 else id - 1
        @setView 'card',
          card: _.find @props.cards, id: id
          nextCard: _.find @props.cards, id: nextId
          prevCard: _.find @props.cards, id: prevId
      '/countries': @setView.bind this, 'countries'
      '/about': @setView.bind this, 'about'
    router.configure
      notfound: @setView.bind this, 'whoops'
    router.on /cards\??(.*)/, (args) =>
      state = qs.toObj args
      # Convert filter ids from str -> number
      if state?.filter?
        state.filter = state.filter.map (el)->
          parseInt el, 10
      @setView 'cards',
        state: state
    router.init('/cards')
    return

  render: ->
    # If the router hasn't kicked in, do nothing
    if not @state?.view
      return R.p className: 'lead', 'TwiStrug is loading'
  
    switch @state.view.name
      when 'home' then return HomeView
        cards: @props.cards
      when 'card' then return CardView @state.view.data
      when 'cards' then return CardsView
        cards: @props.cards
        state: @state.view.data.state
      when 'countries' then return CountriesView()
      when 'board' then return BoardView()
      when 'about' then return AboutView()
      when 'whoops' then return WhoopsView()
    
    WhoopsView()

# Should move this initialisation to all card(s) routes
$.getJSON '/data/cards.json', (cards)->
  # Default ordering should be by stage, then id
  cards = _.sortBy(cards, ['stage', 'id']).map (el)->
    el.key = el.id
    el
  React.renderComponent TwiStrug({cards}), $app

