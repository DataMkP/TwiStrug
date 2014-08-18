R = React.DOM
cx = React.addons.classSet
libs = require '../libs'

CardList = require '../views/CardList'

# Wargameroom card ids differ from TwiStrug (TS deluxe edition)
idsFromWGR = (ids=[])->
  ids.map (id)->
    switch id
      when 35 then 81
      when 98 then 99
      when 99 then 100
      when 100 then 35
      when 101 then 102
      when 102 then 103
      when 107 then 110
      when 109 then 98
      when 110 then 104
      when 111 then 109
      when 112 then 107
      else id

module.exports = React.createClass
  displayName: 'CardsView'

  defaultState: (props)->
    filter = props?.state?.filter

    fullText: if filter then true else false
    cardImg: false
    cardFilterInput: if filter then filter.join(' ') else ''
    sort: 'stage'
    filter: null
    view: 'img'
    filterIsWGR: false

  componentWillReceiveProps: (nextProps) ->
    console.log 'cWRP', nextProps
    if nextProps.state?
      @setState nextProps.state
    else
      @setState @defaultState()

  getInitialState: ->
    _.merge @defaultState(@props), @props.state

  getFilterIds: () ->
    if @state?.filter?
      filterIds = @state.filter.sort(libs.sortNumerical)
        .filter(libs.filterTruthy)
        .filter(libs.filterUnique)
    if not filterIds? then filterIds = []
    return filterIds

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

  groupCards: (cards = @filterAndSortCards())->
    if @state.filter?
      return [cards]

    sort = @state.sort
    if sort == 'side'
      sort = 'owner'
    if @state.sort
      return _.groupBy(cards, sort)
         

  handleFullText: ->
    @setState
      fullText: @refs.fullText.getDOMNode().checked

  handleCardImg: ->
    @setState
      cardImg: @refs.cardImg.getDOMNode().checked

  handleCardFilterChange: ->
    value = @refs.cardFilter.getDOMNode().value
    # If WGR then we have to translate some ids
    isWGR = value.search(/#.*:/) != -1

    # WGR adds "Ops 3: ...", so don't pick those up
    # But still pick up the scoring cards
    ids = value.match(/\d+[^:]|\d+$|#\d:/g)?.map (el)->
      # Strip out any non-digit chars
      el = el.replace /\D/g, ''
      parseInt el, 10
    if value == '' or not ids?
      state =
        cardFilterInput: value
        filter: null
    else
      if isWGR
        ids = idsFromWGR ids
      ids = ids.sort(libs.sortNumerical).filter(libs.filterValidCardIds)
      state =
        cardFilterInput: value
        fullText: true
        filter: ids

    @setState state

  # Format the input field to be just the ids on blur
  handleCardFilterBlur: ->
    filterIds = @getFilterIds()

    @setState
      cardFilterInput: filterIds.join ' '

    if filterIds? and filterIds.length > 0
      libs.qs.set 'filter', filterIds
    else
      libs.qs.delete 'filter'

  handleCardFilterClear: ()->
    @refs.cardFilter.getDOMNode().value = ''
    @setState
      filter:null
      cardFilterInput: ''

    libs.qs.delete 'filter'

  sortGroupTitle: (sort = @state.sort, val)->
    valInt = parseInt val, 10
    switch sort
      when 'ops'
        s = if valInt > 1 then 's' else ''
        if valInt == 0 then 'Scoring' else "#{val} Op#{s}"
      when 'side'
        if val == 'us'
          'USA'
        else if val == 'neutral'
          'Neutral'
        else
          val.toUpperCase()
      when 'stage'
        switch valInt
          when 1 then 'Early War'
          when 2 then 'Mid War'
          when 3 then 'Late war'

  handleViewClick: (view)->
    @setState { view }
    libs.qs.set 'view', view

  render: ->
    console.log 'render', @state, @props
    sortLink = (sort, display) =>
      className = cx active: @state.sort == sort
      ref = "#{sort}Sort"
      onClick = ()->
        libs.qs.set 'sort', sort
      R.a {onClick, ref, className}, display

    cards = @groupCards @filterAndSortCards()

    cardLists = _.map cards, (cards, val)=>
      cardListHeading = null
      if not @state.filter?
        cardListHeading = R.h2 className:'cardList-groupHeading',
          @sortGroupTitle @state.sort, val
      R.div {}, [
        cardListHeading
        CardList
          cardImg: @state.cardImg
          fullText: @state.fullText
          cards: cards
          view: @state.view
      ]

    cardsViewClass = cx
      'cardsView': true
      'cardsView--filtered': @state.filter?
      'cardsView--fullText': @state.fullText

    R.div className: cardsViewClass, [
      R.div className: 'page-header row', [
        R.div className: 'col-md-6', [
          R.div className: 'cardControls', [
            R.span className: 'label', 'Sort by:'
            sortLink 'stage', 'Stage'
            sortLink 'ops', 'Ops'
            sortLink 'side', 'Side'
          ]
          R.div className: 'cardControls', [
            R.label {htmlFor:'', className:''}, 'View: '
            R.i
              onClick: @handleViewClick.bind null, 'img'
              title: 'Card image'
              className: "icon-th-large #{if @state.view == 'img' then 'active' else ''}"
            R.i
              onClick: @handleViewClick.bind null, 'title'
              title: 'Title and ops'
              className: "icon-th #{if @state.view == 'title' then 'active' else ''}"
            R.i
              onClick: @handleViewClick.bind null, 'text'
              title: 'Full text'
              className: "icon-align-left #{if @state.view == 'text' then 'active' else ''}"
            #R.input
              #name: 'fullText'
              #id: 'fullText'
              #type:'checkbox'
              #ref:'fullText'
              #onChange: @handleFullText
              #checked: @state.fullText
            #" "
            #R.label {htmlFor:'fullText', className:'card-show-text-label'}, 'Show card text'
            #" "
            #R.input
              #name: 'cardImg'
              #id: 'cardImg'
              #type:'checkbox'
              #ref:'cardImg'
              #onChange: @handleCardImg
              #checked: @state.cardImg
            #" "
            #R.label {htmlFor:'cardImg', className:'card-show-text-label'}, 'Show card image'
          ]
        ]
        R.div className: 'cards-filter-by-id col-md-6', [
          R.label htmlFor:'cardFilter', className:'cardFilter-label', "Filter by ids "
          R.input
            name: 'cardFilter'
            type: 'text'
            className: 'cardFilter-input'
            ref: 'cardFilter'
            onChange: @handleCardFilterChange
            onBlur: @handleCardFilterBlur
            value: @state.cardFilterInput
            placeholder: 'Paste from Wargameroom or enter ids'
          R.a {className:'cards-filter-by-id-clear', onClick:@handleCardFilterClear}, 'clear'
        ]
      ]
      cardLists
    ]
