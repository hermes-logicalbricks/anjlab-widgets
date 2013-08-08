TimeTools =

  template: "<div class='timepicker dropdown-menu'><div class='times'></div></div>"

class NativeRailsTimepicker
  constructor: (element, options)->
    @element = $(element)
    @rails   = options.rails ? @element.data('rails') ? false

    @element.on {
      keyup: $.proxy(@update, this)
      change: $.proxy(@update, this)
    }

  update: ->
    @time = @element.val()
    @updateRails()

  updateRails: ->
    return if !@rails
    parent = @element.closest('.controls, form, div')
    parts = @time.split(':')
    if parts.length == 2
      parent.find('.js-aw-4i').val(parts[0])
      parent.find('.js-aw-5i').val(parts[1])
    else
      parent.find('.js-aw-4i, .js-aw-5i').val('')

class Timepicker extends NativeRailsTimepicker

  constructor: (element, options)->
    super(element, options)

    @picker  = $(TimeTools.template).appendTo('body').on({
      click: $.proxy(@click, this)
      mousedown: $.proxy(@mousedown, this)
    }, "a")

    @element.on {
      focus: $.proxy(@show, this)
      click: $.proxy(@show, this)
      blur: $.proxy(@hide, this)
    }

    @step      = options.step || @element.data('date-time-step') || 30
    @startTime = options.startTime || (@element.data('date-time-start') || 0) * 60
    @endTime   = options.endTime || (@element.data('date-time-end') || 24) * 60
    @minTime   = options.minTime || (@element.data('date-time-min') || 9) * 60
    @maxTime   = options.maxTime || (@element.data('date-time-max') || 20) * 60
    
    @fillTimes()
    @update()
    @scrollPlaced = false

  initialScroll: ->
    return if @scrollPlaced
    time = @picker.find('.active')
    if time.length > 0
      @picker.find('.times').scrollTop(time.position().top - time.height())
    @scrollPlaced = true

  click: (e)->
    e.stopPropagation()
    e.preventDefault()
    target = $(e.target)

    if target.is 'a'
      @time = target.data('time')
      @setValue()
      @update()
      @element.trigger {
        type: 'changeDate'
        date: @time
      }
      @hide()

  mousedown: (e)->
    e.stopPropagation()
    e.preventDefault()

  update: ->
    super()
    @picker.find('a.active').removeClass('active')
    @picker.find("a[data-time='#{@time}']").addClass('active')

  setValue: ->
    @element.val(@time).change()

  fillTimes: ->
    timeCnt = @startTime
    html = []
    while timeCnt < @endTime
      mm = timeCnt % 60
      hh = Math.floor(timeCnt / 60)
      mm = (if mm < 10 then '0' else '') + mm
      hh = (if hh < 10 then '0' else '') + hh
      time = "#{hh}:#{mm}"
      html.push "<a href='#' data-time='#{time}'"
      html.push " class='night'" if timeCnt <= @minTime || timeCnt >= @maxTime
      html.push ">"
      html.push time
      html.push "</a>"
      timeCnt += @step

    @picker.find('.times').append(html.join(''))

  show: (e) ->
    @picker.show()
    @height = @element.outerHeight()
    @place()
    @initialScroll()
    $(window).on('resize', $.proxy(@place, this))
    if e
      e.stopPropagation()
      e.preventDefault()

    @element.trigger {
      type: 'show'
      date: @time
    }

  place: ->
    offset = @element.offset()
    @picker.css {
      top: offset.top + @height
      left: offset.left
    }

  hide: ->
    @picker.hide()
    $(window).off 'resize', @place

    # @setValue()
    @element.trigger {
      type: 'hide'
      date: @time
    }

nativePicker = false

$.fn.timepicker = (option) ->
  @each ->
    $this = $(this)
    data = $this.data('timepicker')
    options = typeof option == 'object' && option
    if !data
      if nativePicker
        $this.prop('type', 'time')
        $this.data('timepicker', (data = new NativeRailsTimepicker(this, $.extend({}, $.fn.timepicker.defaults,options))))
      else
        $this.data('timepicker', (data = new Timepicker(this, $.extend({}, $.fn.timepicker.defaults,options))))
    data[option]() if typeof option == 'string'

$.fn.timepicker.defaults = { }
$.fn.timepicker.Constructor = Timepicker

$ ->
  input = document.createElement('input')
  input.setAttribute('type', 'time')
  # skip ugly chrome native control for now
  nativePicker = input.type == 'time' && !navigator.userAgent.match(/chrome/i)

  $("input[data-widget=timepicker]").timepicker()
  $(document).on 'focus.data-api click.data-api touchstart.data-api', 'input[data-widget=timepicker]', (e)-> $(e.target).timepicker()