###
knobLayer
###

### ToDo
animation
min: how raw degree constrain?
snap
###


class exports.Knob

  constructor: (options = {})->

    if not options.knobLayer or not options.indicatorLayer
      throw new Error("Can't initialize Knob: parameter 'knobLayer' & 'indicatorLayer' are required.")
      return

    @knob = options.knobLayer
    @indicator = options.indicatorLayer
    @_indicatorFrame = @_abs2relLayper options.indicatorLayer, options.knobLayer
    @_indicatorFrame.width = @indicator.width
    @_indicatorFrame.height = @indicator.height

    options.knobRadius ?= options.knobLayer.width/2
    options.indicatorRadius ?= options.indicatorLayer.width/2
    options.thickness ?= options.knobRadius
    options.orbitRadius ?= @_getMagnitude @_indicatorFrame

    # options.snap ?= false
    options.onlyIndicatorDraggable ?= false
    options.infinite ?= false
    # if options.arcRange then options.infinite = false
    # options.arcRange ?= [0, 360]
    options.clockCoordinateSystem ?= true
    @angle = options.startAngle ?= 0
    @_rawAngle = if options.clockCoordinateSystem then @angle-90 else @angle
    @_targetLayer = if options.onlyIndicatorDraggable then options.indicatorLayer else options.knobLayer


    # Object.defineProperty @indicator, 'angle',
    #   get: => @_angle or 0
    #   set: (angle)=>
    #     @_angle = angle
    #     {x: @_indicatorFrame.x, y: @_indicatorFrame.y} = @_deg2vector @_rawAngle, options.orbitRadius
    #     abs = @_rel2absLayer @_indicatorFrame, @knob
    #     @indicator.screenFrame =
    #       x: abs.x
    #       y: abs.y
    #     print @indicator.screenFrame, abs

    # To solve issue, use drag event rather than touch event https://github.com/koenbok/Framer/issues/245
    @shadow = new Layer
      name: 'knobShadow'
      width: @_targetLayer.width
      height: @_targetLayer.height
      x: @_targetLayer.screenFrame.x
      y: @_targetLayer.screenFrame.y
      borderRadius: options.knobRadius
      opacity: 1
      index: @_targetLayer.index + 1
    @shadow.draggable.enabled = true
    @shadow.draggable.momentum = false


    cursorFrame = {}
    curVector = {}

    @shadow.on Events.DragStart, (event, draggable, layer)=>
      cursorX = if Utils.isMobile() then draggable.layerCursorOffset.x else event.offsetX
      cursorY = if Utils.isMobile() then draggable.layerCursorOffset.y else event.offsetY
      cursorFrame = @_abs2relPos {
        x: cursorX + @_targetLayer.screenFrame.x
        y: cursorY + @_targetLayer.screenFrame.y
      }, @knob

      curVector = _.clone cursorFrame


    @shadow.on Events.DragMove, (event, draggable, layer)=>
      preVector = _.clone curVector
      curVector =
        x: cursorFrame.x + draggable.offset.x
        y: cursorFrame.y + draggable.offset.y

      delta = @_vector2deg preVector, curVector
      direction = if @_crossProduct( preVector, curVector ) > 0 then 1 else -1

      @_rawAngle += delta*direction
      @angle = @_degConvert @_rawAngle, options.infinite, options.clockCoordinateSystem
      {x: @_indicatorFrame.x, y: @_indicatorFrame.y} = @_deg2vector @_rawAngle, options.orbitRadius
      abs = @_rel2absLayer @_indicatorFrame, @knob
      @indicator.screenFrame =
        x: abs.x
        y: abs.y


    @shadow.on Events.DragEnd, (event, draggable, layer)=>
      @shadow.x = @_targetLayer.screenFrame.x
      @shadow.y = @_targetLayer.screenFrame.y


  ##
  _getMidPos: (pos, size)->
    return pos + size / 2

  _getMinPos: (pos, size)->
    return pos - size / 2

  # relative mid x
  _abs2relLayper: (relativeLayer, baseLayer)->
    return {
      x: @_getMidPos(relativeLayer.screenFrame.x, relativeLayer.width) - @_getMidPos(baseLayer.screenFrame.x, baseLayer.width)
      y: @_getMidPos(relativeLayer.screenFrame.y, relativeLayer.height) - @_getMidPos(baseLayer.screenFrame.y, baseLayer.height)
    }

  _abs2relPos: (relativeVector, baseLayer)->
    return {
      x: relativeVector.x - @_getMidPos(baseLayer.screenFrame.x, baseLayer.width)
      y: relativeVector.y - @_getMidPos(baseLayer.screenFrame.y, baseLayer.height)
    }

  # absolute x
  _rel2absLayer: (relativeFrame, baseLayer)->
    return {
      x: @_getMinPos(relativeFrame.x, relativeFrame.width) + @_getMidPos(baseLayer.screenFrame.x, baseLayer.width)
      y: @_getMinPos(relativeFrame.y, relativeFrame.height) + @_getMidPos(baseLayer.screenFrame.y, baseLayer.height)
    }


  ## Vector Untils
  _getMagnitude: (vector)->
    return Math.sqrt vector.x*vector.x + vector.y*vector.y

  _dotProduct: (vector1, vector2)->
    return vector1.x*vector2.x + vector1.y*vector2.y

  _crossProduct: (vector1, vector2)->
    return vector1.x*vector2.y - vector1.y*vector2.x

  _vector2deg:(v1, v2)->
    return Math.acos( Math.min(1, (@_dotProduct(v1, v2) / (@_getMagnitude(v1)*@_getMagnitude(v2)))) ) * (180 / Math.PI)

  _deg2vector: (deg, magnitude)->
    return {
      x: magnitude*Math.cos deg*(Math.PI/180)
      y: magnitude*Math.sin deg*(Math.PI/180)
    }


  _degConvert: (angle, infinite, clockCoordinateSystem)->
    degreeShifted = if clockCoordinateSystem then angle+90 else angle
    if infinite then return degreeShifted
    else if degreeShifted > 0 then return degreeShifted%360
    else return degreeShifted%360+360