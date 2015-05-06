
require "lotus-require"
define = require "define"
{ setType, setKind } = require "type-utils"

Finder = module.exports = (regex) ->

  finder = (target) ->
    finder.target = target
    finder.next()

  setType finder, Finder

  define.options =
    configurable: no

  define finder,

    target:
      value: ""
      willSet: (newValue) ->
        unless typeof newValue is "string"
          error = TypeError "'target' must be a String." 
          error.code = "BAD_TARGET_TYPE"
          throw error
        @offset = 0
        return newValue

    _groups:
      # enumerable: no
      value: []

  finder._regex = regex

  # finder.group = if finder.groups.length > 1 then 1 else 0

  return finder

setKind Finder, Function

define Finder, ->
  
  @options = 
    configurable: no
    writable: no

  @ 
    find: (regex, target) ->
      _defaultFinder._regex = regex
      return _defaultFinder target

    test: (regex, target) ->
      _defaultFinder._regex = regex
      return _defaultFinder.test target

  @ Finder.prototype, ->

    @ 
      next: ->
        return null if @offset < 0
        match = @_regex.exec @target
        unless @group < @groups.length
          error = RangeError "'this.group' must be less than #{@groups.length}, but equaled #{@group}."
          error.code = "BAD_GROUP"
          throw error
        result = null
        result = match[@group] if match?
        return result if result?
        @_regex.lastIndex = -1
        return null

      each: (target, iterator) ->
        iterator = target if typeof iterator isnt "function" and typeof target is "function"
        target = @target if typeof target isnt "string"
        return _tempTarget.call this, target, =>
          index = 0
          loop
            match = @next()
            break if match is null
            iterator match, index++
          return null

      map: (target, iterator) ->
        map = []
        @each target, (match, index) ->
          map.push iterator match, index
        return map

      reduce: (target, initial, iterator) ->
        unless iterator instanceof Function
          iterator = initial
          initial = target
          target = @target
        @each target, (match, index) ->
          initial = iterator initial, match, index
        return initial

      all: (target) ->
        matches = []
        @each target, (match) -> matches.push match
        return matches

      test: (target) ->
        unless typeof target is "string"
          error = TypeError "'target' must be a String."
          error.code = "BAD_TARGET_TYPE"
          throw error
        return _tempTarget.call this, target, =>
          match = @_regex.exec target
          return match?

      groups: get: -> @_groups

    @options.writable = yes

    @ 
      offset:
        get: -> @_regex.lastIndex
        set: (newValue) ->
          unless typeof newValue is "number"
            error = TypeError "'this.offset' must be a Number."
            error.code = "BAD_OFFSET_TYPE"
            throw error
          if newValue < 0
            error = RangeError "@offset must be >= 0"
            error.code = ""
            throw error
          @_regex.lastIndex = newValue

      group:
        value: 0
        willSet: (newValue) ->
          throw RangeError "You must pass a Number >= 0 when setting @group." unless newValue >= 0
          throw RangeError "You must pass a Number < #{@groups.length} when setting @group." unless newValue < @groups.length
          return newValue

      pattern:
        get: -> @_regex.source
        set: (newValue) ->
          flags = _getRegexFlags newValue, {}
          flags.g = yes
          flags = Object.keys(flags).join ""
          newValue = newValue.replace "\\", "\\\\"
          @_regex = RegExp newValue, flags
          @offset = 0

      _regex:
        enumerable: no
        willSet: (newValue, oldValue) ->
          newValue ?= ""
          if typeof newValue is "string"
            @pattern = newValue
            return @_regex
          else if newValue instanceof RegExp
            newValue = if newValue.global then newValue else _setRegexFlags newValue, { global: true }
            @_groups = _getGroups newValue
            return newValue
          throw TypeError "You must pass either a RegExp or String when setting @_regex."

    for key in ["ignoreCase", "multiline"]
      @ key,
        get: -> @_regex[key]
        set: (newValue) ->
          return if @_regex[key] is newValue
          newFlags = {}
          newFlags[key] = newValue
          @_regex = _setRegexFlags @_regex, newFlags
      

### PRIVATE VARS ###


_parenRegex = /(\||\(|\))/g

_regexFlags =
  global: "g"
  ignoreCase: "i"
  multiline: "m"

_getRegexFlags = (input, output) ->
  for key, value of _regexFlags
    inputValue = input[key]
    if inputValue is true
      output[value] = true
    else if inputValue is false
      delete output[value]
  return output

_setRegexFlags = (regex, newFlags) ->
  flags = {}
  _getRegexFlags regex, flags
  _getRegexFlags newFlags, flags
  newRegex = RegExp regex.source, Object.keys(flags).join ""
  newRegex.lastIndex = regex.lastIndex
  return newRegex

_getGroups = (regex) ->
  parens = []
  groups = [regex.source]
  groupIndex = 0
  _parenRegex.lastIndex = 0
  loop
    match = _parenRegex.exec regex.source
    break if !match?
    continue if regex.source[_parenRegex.lastIndex - 2] is "\\" 
    switch match[0]
      when "("
        parens.push
          index: _parenRegex.lastIndex
          group: ++groupIndex
      when ")"
        paren = parens.pop()
        continue if !paren?
        groups[paren.group] = regex.source.slice paren.index, _parenRegex.lastIndex - 1
      when "|"
        parens.pop()
  return groups

_tempTarget = (target, fn) ->
  _offset = @offset
  _target = @target
  @target = target
  result = fn()
  @target = _target
  @_regex.lastIndex = _offset # Avoid range errors in case _offset is under zero.
  return result

_defaultFinder = Finder ""
